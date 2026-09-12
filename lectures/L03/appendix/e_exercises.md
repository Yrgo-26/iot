# Bilaga E

## Övningsuppgifter
Uppgifterna bygger vidare på den frame och den parser ni skrev i [L01](../../L01/README.md) och
[L02](../../L02/README.md), och tar dem hela vägen till en liten simulerad buss med flera noder,
kontrollerade fel, kvittens och omsändning.

De är indelade i fyra delar, en per bilaga:

| Del | Bilaga | Uppgifter |
|---|---|---|
| 1 | [Bilaga A](./a_bus_and_routing.md) - buss och routing | 1-5 |
| 2 | [Bilaga B](./b_error_model.md) - felmodell | 6-9 |
| 3 | [Bilaga C](./c_ack_nack.md) - ACK/NACK | 10-15 |
| 4 | [Bilaga D](./d_timeout_retry_duplicate.md) - timeout, retry, dubbletter | 16-21 |

**Del 1 är den viktiga.** Den bygger simuleringen som de tre övriga delarna vilar på, och den
görs på lektionstid. Del 2-4 är självstudier: de är kursens sista arbete med det egna protokollet
innan CAN tar över från [L04](../../L04/README.md), och de är duggans tyngdpunkt. Den som inte
hinner koda dem ska ändå kunna resonera sig igenom dem på papper - det är exakt den formen duggan
har.

---

# Del 1 - Buss och routing

Vi bygger en simulerad miljö med:
* En buss (`comm::bus::Interface` samt `comm::bus::Stub`).
* Noder (`comm::node::Interface` samt `comm::node::Stub`).
* Varje nod använder:
    * `comm::frame::Parser`.
    * `comm::frame::Frame`.
    * `handleFrame()` från testprogrammet i L02.

---

### **1.** Skapa buss-interface
Implementera följande interface `comm::bus::Interface` för databussen i en ny fil
`comm/bus/interface.hpp`:

```cpp
/**
 * @brief Bus interface.
 */
#pragma once

#include <cstdint>

namespace comm
{
/** Node interface. */
namespace node { class Interface; }
} // namespace comm

namespace comm::bus
{
/**
 * @brief Bus interface.
 */
class Interface
{
public:
    /**
     * @brief Destructor.
     */

    /**
     * @brief Add node to the bus.
     * 
     * @param[in] node Node to add.
     * 
     * @return True if the node was added, false otherwise.
     */
    //! @todo Name the method 'addNode()'.

    /**
     * @brief Send byte on the bus (broadcast).
     *
     *        The byte is delivered to all registered nodes.
     *        Routing is performed in the nodes, not in the bus.
     *
     * @param[in] byte Byte to send.
     *
     * @return True if the byte was queued successfully, false otherwise.
     */
    //! @todo Name the method 'sendByte()'.

    /**
     * @brief Increment the clock.
     * 
     *        Deliver pending bytes to all nodes.
     */
    //! @todo Name the method 'tick()'.

    /**
     * @brief Reset the bus and all connected nodes.
     */
    //! @todo Name the method `reset()`.
};
} // namespace comm::bus
```

Funktion:
* `addNode()` registrerar en nod på bussen.
* `sendByte()` lägger en byte i bussens interna kö.
* `tick()` levererar bytes till noderna.
* `reset()` återställer bussen och samtliga anslutna noder.

---

### **2.** Skapa nod-interface
Implementera följande interface `comm::node::Interface` för en nod i en ny fil `comm/node/interface.hpp`:

```cpp
/**
 * @brief Node interface.
 */
#pragma once

#include <cstdint>

namespace comm::node
{
/**
 * @brief Node interface.
 */
class Interface
{
public:
    /**
     * @brief Destructor.
     */

    /**
     * @brief Get the node address.
     * 
     * @return Node address.
     */
    //! @todo Name the method 'address()'.

    /**
     * @brief Receive byte from the bus.
     * 
     *        This method is invoked by the bus when a byte is delivered.
     *        The node is responsible for feeding the byte into its parser.
     * 
     * @param[in] byte Received byte.
     */
    //! @todo Name the method 'onReceive()'.

    /**
     * @brief Execute one tick of node logic.
     * 
     *        The node should run its parser and handle complete frames.
     *        Any required transmissions should be queued on the bus.
     */
    //! @todo Name the method 'tick()'.

    /**
     * @brief Reset the node.
     */
    //! @todo Name the method `reset()`.
};
} // namespace comm::node
```

Funktion:
* `address()` ger nodens address.
* `onReceive()` tar emot bytes från bussen (broadcast).
* `tick()` driver nodens logik utan blockering.
* `reset()` återställer nodens interna tillstånd.

---

### **3.** Implementera `comm::bus::Stub`
Implementera en buss-stub i en ny fil `comm/bus/stub.hpp`:

Bussen ska följande interna konstanter (`static constexpr`):
* `MaxNodeCount` = `10U`
* `MaxQueuedBytes` = `20U`

Bussen ska följande medlemsvariabler:
* `myNodes[MaxNodeCount]`:
    * Array med pekare till anslutna noder.
* `myQueue[MaxQueuedBytes]`:
    * Intern kö som lagrar data (bytes) som ska skickas till alla noder.
    * Ska arbeta efter FIFO-principen (*First In First Out*), dvs. den äldsta byten ska
    poppas/tas ut först.
* `myNodeCount`:
    * Antalet anslutna noder
* `myQueueLen`:
    * Antalet bytes i den interna kön.
* `myFirstByteIndex`:
    * Index för den första (äldsta) byten i den interna kön.
* `myNextByteIndex`:
    * Index där nästa byte ska placeras i den interna kön.

Implementera följande metoder i en ny fil `comm/bus/stub.cpp`:
* `sendByte()`:
    * Given byte läggs i den intern kön `myQueue` om utrymme finns.
    * Använd `myNextByteIndex` för att placera den nya byten längst bak i kön.
    * Inkrementera `myNextByteIndex` efter skrivningen och se till att dena hålls inom bufferns storlek:  
    `myNextByteIndex = myNextByteIndex % MaxQueuedBytes`.
    * `True` ska returneras om given byte lades till ska `true` annars `false`.
* `tick()`:
    * Om kön innehåller data:
        * Poppa en byte enligt FIFO-principen, dvs. den äldsta byten ska poppas.
        * Använd `myFirstByteIndex` för att läsa ut den äldsta byten.
        * Inkrementera `myFirstByteIndex` efter läsningen och se till att det hålls inom 
        bufferns storlek:  
        `myFirstByteIndex = myFirstByteIndex % MaxQueuedBytes`.
        * Leverera byten till alla noder genom att anropa `node.onReceive(byte)`.
* `reset()`:
    * Nollställer samtliga medlemsvariabler.
    * Resettar samtliga anslutna noder via `myNodes[i]->reset()`.

---

### **4.** Implementera `comm::node::Stub`
Implementera en nod-stub i en ny fil `comm/node/stub.hpp`:
* Har en frame-parser `myParser`.
* Har en referens till ett buss-interface `myBus`.
* Har ett 16-bitars sensorvärde `myVal`.
* Har en 8-bitars adress `myAddr`.

Implementera följande metoder i en ny fil `comm/node/stub.cpp`:
* Konstruktorn:
    * Tar emot en address, en buss-referens samt ett sensorvärde.
    * Som default ska sensorvärdet sättas till `0`.
    * Sparar given address i `myAddr`.
    * Sparar given buss-referens i `myBus`.
    * Sparar givet sensorvärde i `myVal`.
    * Kopplar noden till bussen (`myBus.addNode(*this)`).
* `address()`:
    * Returnerar `myAddr`.
* `onReceive(std::uint8_t byte)`:
    * Matar byte till frame-parsern.
* `tick()`:
    * Om frame-parsern har en komplett frame:
        * Extrahera framen, avsluta metoden vid fel.
        * Om `frame.dstAddr != myAddr` → ignorera.
        * Annars:
            * Resetta parsern.
            * Anropa metoden [handleFrame()](./code/node/stub.cpp) för att svara på framen.
            * Om `handleFrame()` returnerar `true`:
                * Serialisera framen.
                * Resetta bussen via `myBus.reset()`.
                * Skicka bytes via `myBus.sendByte()`.
            * Annars, gör ingenting.
* `reset()`:
    * Resettar den interna parsern.
* `handleFrame()`:
    * Privat metod, implementerad i [./code/node/stub.cpp](./code/node/stub.cpp), som kan klistras
    in direkt.
    * Metoden vidareutvecklar och ersätter motsvarande metod från L02.
    * Filerna `comm/frame/handler.hpp` och `comm/frame/handler.cpp` kan därför tas bort.

---

### **5.** Validera implementationen
Kompilera och kör testprogrammet i [main.cpp](./code/main.cpp) i en Linuxterminal:

```bash
make
```

Det som sker i testet är att:
* Tre noder skapas på adressen `1-3`.
* Noderna ansluts till en databuss.
* En status request skickas från nod 1 till nod 2.
* Nod 2 svarar med ett status response innehållande dess sensorvärde.

---

# Del 2 - Felmodell

En buss som alltid levererar varje byte i rätt ordning är inte en buss, utan en funktionsanrop
med extra steg. Uppgifterna nedan gör felen **deterministiska**: de inträffar på exakt samma
byte varje körning, så att ett testfall som fångar ett fel fångar det igen imorgon. Se
[bilaga B](./b_error_model.md).

---

### **6.** Implementera deterministisk byte-drop
Utöka `comm::bus::Stub`:
* Lägg till byteräknaren `std::uint8_t myByteCounter`.
* Inkrementera den för varje skickad byte.
* Droppa byte nummer 5.

Verifiera att:
* Parsern misslyckas att parsa framen.
* Systemet återgår till vänteläge, dvs. parsern återgår till tillståndet `WaitForSof1`.

---

### **7.** Implementera bitflip
Modifiera bussen:

* Om `3U == myByteCounter`:
    * Flippa lägsta biten.

Verifiera att:
* Felet detekteras genom att checksumman blir fel.
* Framen avvisas.

---

### **8.** Implementera fördröjningskö
Istället för att leverera byten direkt i `tick()`:
* Lägg till fördröjningsräknaren `std::uint8_t myDelayCounter`, som initieras till `5U`.
* Lagra byten tillsammans med fördröjningsräknaren.
* Dekrementera `myDelayCounter` varje tick.
* Leverera först när `myDelayCounter` har räknat ned till `0U`.

Verifiera att:
* Systemet fungerar även med fördröjning.
* Ingen blockering uppstår.

---

### **9.** Två frames back-to-back med fel
Skicka:
* PING
* PING

Inför ett fel i den första framen. Verifiera att:
* Den första framen avvisas.
* Den andra framen tas emot korrekt.

**Reflektera**, innan ni går vidare till del 3:
* Hur vet sändaren att en frame tappades?
* Hur vet mottagaren att sändaren behöver skicka igen?
* Räcker checksumma för tillförlitlighet?

---

# Del 3 - ACK och NACK

Vi bygger vidare på samma simulering:
* Bus: broadcast, tick-driven, deterministisk felmodell.
* Node: parser + routing.
* Nytt: kvittenslogik. Se [bilaga C](./c_ack_nack.md).

---

### **10.** Lägg till ACK och NACK i `comm::frame::Type`
Uppdatera `comm::frame::Type` med följande frametyper:
* Lägg till `Ack`.
* Lägg till `Nack`.

Verifiera:
* `isTypeValid()` (om ni har en sådan) fungerar även efter utökning.
* `Unknown` ska fortfarande vara sista värdet.

---

### **11.** Skapa funktioner för att bygga ACK/NACK
Skapa två funktioner i exempelvis `comm/transport/utils.hpp`:

```cpp
bool makeAck(const comm::frame::Frame& rxFrame, comm::frame::Frame& txFrame) noexcept;
bool makeNack(const comm::frame::Frame& rxFrame, comm::frame::Frame& txFrame) noexcept;
```

Regler:
* `DST/SRC` ska swappas jämfört med `rxFrame`.
* `SEQ` ska vara samma som i `rxFrame`.
* `LEN = 0U`.
* `TYPE = Ack` eller `TYPE = Nack`.

---

### **12.** Skapa ett interface för transportlagret
Implementera följande interface:

```cpp
#include <cstdint>

/** Frame implementation. */
namespace comm::frame { class Frame; }

namespace comm::transport
{
/**
 * @brief Transport interface.
 */
class Interface
{
public:
    /**
     * @brief Destructor.
     */

    /**
     * @brief Execute one tick of transport logic.
     */
    //! @todo Name the method 'tick()'.

    /**
     * @brief Provide a received application frame to the transport.
     * 
     *        The transport may generate ACK/NACK as a result.
     * 
     * @param[in] frame Received frame.
     */
    //! @todo Name the method 'onRxFrame()'.

    /**
     * @brief Check whether transport has a frame to transmit.
     * 
     * @return True if a TX frame is available, false otherwise.
     */
    //! @todo Name the method 'hasTxFrame()'.

    /**
     * @brief Pop next TX frame from transport.
     * 
     * @param[out] out Retrieved TX frame.
     * 
     * @return True if a frame was popped, false otherwise.
     */
    //! @todo Name the method 'popTxFrame()'.
};
} // namespace comm::transport
```

---

### **13.** Implementera `comm::transport::Stub`
Implementera en stubb med följande minimibeteende:
* När `onRxFrame()` anropas:
    * Om frame är en applikationsframe och är adresserad till noden:
        * Skapa och köa ett ACK.
* Vid fel i frame:
    * Skapa och köa ett NACK om ni kan (se [bilaga C](./c_ack_nack.md)).
* `hasTxFrame()` och `popTxFrame()` ska hantera en enkel FIFO-kö av frames.

**Notera:**
* I den här delen behöver transporten inte vänta på ACK.
* Den ska endast generera kvittens. Väntan kommer i del 4.

---

### **14.** Uppdatera `comm::node::Stub`
Uppdatera nodstubbens `tick()`:
* När en frame extraherats och noden är den avsedda mottagaren:
    * Ge framen till transporten via `transport.onRxFrame(frame)`.
    * Hantera applikationslogik (PING → PONG) som tidigare.

* Efter att noden hanterat RX:
    * Om `transport.hasTxFrame()`:
        * Poppa framen, serialisera och skicka bytes via `bus.sendByte(...)`.

---

### **15.** Demonstrera ACK/NACK med deterministiska fel
Skapa minst tre scenarion:

1) Inga fel:
* PING från A till B.
* B skickar PONG.
* B skickar ACK på PING.

2) Korrupt byte (uppgift 7):
* Korrupta en byte i PING.
* B ska inte leverera PING till applikationslogik.
* (Om möjligt) B skickar NACK.

3) Drop (uppgift 6):
* Droppa hela PING-framen (eller en byte så att framen aldrig blir valid).
* Ingen ACK/NACK kommer fram.
* Diskutera: detta leder till timeout/retry i del 4.

**Reflektera**, innan ni går vidare till del 4:
* Vad gör sändaren om ACK uteblir?
* Hur länge ska sändaren vänta?
* Vad händer om sändaren skickar om och mottagaren får en dubblett?

---

# Del 4 - Timeout, retry och dubbletter

Sista delen, och den som stänger cirkeln: en sändare som inte får svar måste själv bestämma sig
för att något gått fel. Se [bilaga D](./d_timeout_retry_duplicate.md).

---

### **16.** Utöka transport-stubben
Lägg till följande i `comm::transport::Stub`:
* `bool myWaitingForAck`
* `std::uint16_t myExpectedSeq`
* `std::uint16_t myTimeoutCounter`
* `std::uint16_t myMaxTimeouts`
* `std::uint8_t myRetryCounter`
* `std::uint8_t myMaxRetries`

Se till att `myMaxTimeouts` initieras direkt via konstruktorn.

När en frame skickas:
* Sätt `myWaitingForAck` till `true`.
* Sätt `myExpectedSeq`.
* Initiera `myTimeoutCounter`.

---

### **17.** I `onRxFrame()`
Om frame är:
* `Type::Ack`
* Och `SEQ == myExpectedSeq`

Gör då följande:
* Stoppa timeout-räknaren.
* Sätt `myWaitingForAck` till `false`.
* Nollställ `myRetryCounter`.

---

### **18.** I `tick()`
Om:
* `myWaitingForAck == true`
* `myTimeoutCounter == 0`

Gör då följande:
* Om `myRetryCounter < myMaxRetries`
    * Skicka om senaste frame.
    * Inkrementera retry-counter.
    * Återställ timeout-counter.
* Annars: rapportera permanent fel.

---

### **19.** Implementera dubblettdetektion
I noden:
* Spara senaste behandlade SEQ per avsändare.
* Om samma SEQ tas emot igen:
    * Kör inte applikationslogik.
    * Skicka ACK igen.

Verifiera att applikationskoden enbart körs en gång.

---

### **20.** Drop-test
* Droppa första framen.
* Timeout → retry.
* ACK på retry.

Verifiera att applikationskoden enbart körs en gång.

---

### **21.** Drop ACK-test
* Låt mottagaren ta emot frame.
* Droppa ACK.
* Timeout → retry.
* Mottagaren ska:
    * Inte köra applikationslogik igen.
    * Skicka ACK igen.

Fördröj sedan ACK med 2 tick, och justera timeout så att ingen onödig retry sker.

**Reflektera:**
* Hur väljer man timeout-värde?
* Vad händer om timeout är för kort?
* Vad händer om timeout är för lång?
* Vilka av mekanismerna i del 3 och 4 behöver **inte** skrivas i mjukvara på en CAN-buss, och
  varför? Spar svaret till [L04](../../L04/README.md).

---
