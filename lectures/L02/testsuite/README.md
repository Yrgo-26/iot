# Utdelad testsvit - `comm::frame::Frame` och `comm::frame::Parser`

Testsviten hör till [L02](../README.md) och är byggd mot
[`qacademy::test`](../../../libs/test/README.md), samma ramverk som används i **P03**.

**Ni skriver inte testerna.** De är utdelade; ert jobb är att få dem att passera, och att kunna
läsa vad de säger när de fallerar. Att skriva tester lär ni er i *Mjuk- och hårdvarutestning*,
efter den här kursen.

---

## Innehåll

| Fil | Innehåll |
|---|---|
| [Makefile](./Makefile) | Bygger testramverket och länkar in det. |
| [test/main.cpp](./test/main.cpp) | Kör alla registrerade testfall. |
| [test/comm/frame/frame_test.cpp](./test/comm/frame/frame_test.cpp) | Enhetstester för `comm::frame::Frame`: serialisering, deserialisering och checksumma. |
| [test/comm/frame/parser_test.cpp](./test/comm/frame/parser_test.cpp) | Enhetstester för `comm::frame::Parser`: skräpdata före SOF, trasig checksumma, och två frames back-to-back. |

Lägg in er egen `frame.cpp` och `parser.cpp` i `source/`, och era headers i `include/`.

---

## Att bygga och köra

Testramverket ligger som git-submodul i repots rot. Checka ut det en gång:

```bash
git submodule update --init
```

Bygg och kör sedan:

```bash
make build
make test
```

`make` utan argument gör båda.

---

## När något fallerar

```text
FAILED: EXPECT_EQ(buf[Offset::Len], frame.payloadLen) at frame_test.cpp:63
```

Läs i den här ordningen, och öppna er egen kod **sist**:

1. **Testnamnet** - vilket krav är brutet?
2. **Arrange-delen** - under vilka förutsättningar?
3. **Assert-raden** - vad förväntades?
4. Först nu: er egen kod.

Mer om det i [L05 bilaga B](../../L05/appendix/b_unit_testing.md).

---
