/**
 * @brief Unit tests for comm::frame::Parser.
 */
#include "comm/frame/parser.hpp"

#include <cstddef>
#include <cstdint>

#include "comm/frame/def.hpp"
#include "comm/frame/frame.hpp"
#include "qacademy/test/test.hpp"

namespace
{
using comm::frame::Frame;
using comm::frame::Parser;
using comm::frame::Type;

/**
 * @brief Build a frame and serialize it into the given buffer.
 *
 * @param[out] buf    Buffer to serialize into.
 * @param[in]  bufLen Length of the buffer.
 * @param[in]  type   Frame type.
 * @param[in]  seqNr  Sequence number.
 *
 * @return The number of serialized bytes.
 */
std::size_t buildFrame(std::uint8_t* const buf, const std::size_t bufLen, const Type type,
                       const std::uint16_t seqNr) noexcept
{
    Frame frame{};
    frame.type       = type;
    frame.dstAddr    = 0x25U;
    frame.srcAddr    = 0x17U;
    frame.seqNr      = seqNr;
    frame.payloadLen = 3U;
    frame.payload[0] = 0x10U;
    frame.payload[1] = 0x20U;
    frame.payload[2] = 0x30U;
    return frame.serialize(buf, bufLen);
}

/**
 * @brief Feed a buffer to a parser, one byte at a time.
 *
 * @param[in,out] parser Parser to feed.
 * @param[in]     buf    Buffer to feed.
 * @param[in]     len    Number of bytes to feed.
 */
void feed(Parser& parser, const std::uint8_t* const buf, const std::size_t len) noexcept
{
    for (std::size_t i{}; i < len; ++i)
    {
        static_cast<void>(parser.processByte(buf[i]));
    }
}

// -----------------------------------------------------------------------------
TEST(Parser, isNotReadyBeforeAnyBytes)
{
    // Arrange.
    Parser parser{};

    // Act & Assert.
    EXPECT_FALSE(parser.isFrameReady());
}

// -----------------------------------------------------------------------------
TEST(Parser, extractsCompleteFrame)
{
    // Arrange.
    std::uint8_t buf[comm::frame::MaxFrameLen]{};
    const std::size_t len{buildFrame(buf, sizeof(buf), Type::StatusResponse, 0x7F05U)};
    Parser parser{};

    // Act.
    feed(parser, buf, len);

    // Assert.
    EXPECT_TRUE(parser.isFrameReady());

    Frame frame{};
    EXPECT_TRUE(parser.extractFrame(frame));
    EXPECT_EQ(static_cast<std::uint8_t>(frame.type),
              static_cast<std::uint8_t>(Type::StatusResponse));
    EXPECT_EQ(frame.dstAddr, 0x25U);
    EXPECT_EQ(frame.srcAddr, 0x17U);
    EXPECT_EQ(frame.seqNr, 0x7F05U);
    EXPECT_EQ(frame.payloadLen, 3U);
    EXPECT_EQ(frame.payload[0], 0x10U);
    EXPECT_EQ(frame.payload[1], 0x20U);
    EXPECT_EQ(frame.payload[2], 0x30U);
}

// -----------------------------------------------------------------------------
TEST(Parser, recoversFromGarbageBeforeSof)
{
    // Arrange: four bytes of noise, then a complete frame.
    std::uint8_t buf[comm::frame::MaxFrameLen]{};
    const std::size_t len{buildFrame(buf, sizeof(buf), Type::Ping, 0x0001U)};
    const std::uint8_t garbage[]{0x32U, 0x74U, 0x00U, 0xFFU};
    Parser parser{};

    // Act.
    feed(parser, garbage, sizeof(garbage));
    feed(parser, buf, len);

    // Assert.
    EXPECT_TRUE(parser.isFrameReady());

    Frame frame{};
    EXPECT_TRUE(parser.extractFrame(frame));
    EXPECT_EQ(frame.seqNr, 0x0001U);
}

// -----------------------------------------------------------------------------
TEST(Parser, rejectsFrameWithBrokenChecksum)
{
    // Arrange: flip one payload byte after the checksum was computed.
    std::uint8_t buf[comm::frame::MaxFrameLen]{};
    const std::size_t len{buildFrame(buf, sizeof(buf), Type::StatusResponse, 0x7F05U)};
    buf[comm::frame::Offset::Data] ^= 0x01U;
    Parser parser{};

    // Act.
    feed(parser, buf, len);

    // Assert: the framing is complete, but extraction validates and rejects the frame.
    EXPECT_TRUE(parser.isFrameReady());

    Frame frame{};
    EXPECT_FALSE(parser.extractFrame(frame));
}

// -----------------------------------------------------------------------------
TEST(Parser, rejectsFrameWithTooLongPayload)
{
    // Arrange: a length field larger than the parser's buffer can hold.
    std::uint8_t buf[comm::frame::MaxFrameLen]{};
    const std::size_t len{buildFrame(buf, sizeof(buf), Type::Ping, 0x0001U)};
    buf[comm::frame::Offset::Len] = static_cast<std::uint8_t>(comm::frame::MaxPayloadLen + 1U);
    Parser parser{};

    // Act.
    feed(parser, buf, len);

    // Assert.
    EXPECT_FALSE(parser.isFrameReady());
}

// -----------------------------------------------------------------------------
TEST(Parser, findsBothFramesBackToBack)
{
    // Arrange.
    std::uint8_t first[comm::frame::MaxFrameLen]{};
    std::uint8_t second[comm::frame::MaxFrameLen]{};
    const std::size_t firstLen{buildFrame(first, sizeof(first), Type::Ping, 0x0001U)};
    const std::size_t secondLen{buildFrame(second, sizeof(second), Type::Pong, 0x0002U)};
    Parser parser{};

    // Act & Assert: the first frame.
    feed(parser, first, firstLen);
    EXPECT_TRUE(parser.isFrameReady());

    Frame frame{};
    EXPECT_TRUE(parser.extractFrame(frame));
    EXPECT_EQ(frame.seqNr, 0x0001U);

    // Act & Assert: the second frame, after a reset.
    parser.reset();
    EXPECT_FALSE(parser.isFrameReady());

    feed(parser, second, secondLen);
    EXPECT_TRUE(parser.isFrameReady());
    EXPECT_TRUE(parser.extractFrame(frame));
    EXPECT_EQ(frame.seqNr, 0x0002U);
}

// -----------------------------------------------------------------------------
TEST(Parser, resetDiscardsPartialFrame)
{
    // Arrange: feed half a frame, then reset.
    std::uint8_t buf[comm::frame::MaxFrameLen]{};
    const std::size_t len{buildFrame(buf, sizeof(buf), Type::Ping, 0x0001U)};
    Parser parser{};
    feed(parser, buf, len / 2U);

    // Act.
    parser.reset();
    feed(parser, buf, len);

    // Assert: the frame fed after the reset parses cleanly.
    EXPECT_TRUE(parser.isFrameReady());
}
} // namespace
