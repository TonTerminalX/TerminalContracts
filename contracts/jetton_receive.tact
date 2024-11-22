import "@stdlib/deploy";

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

fun calculateJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): Address {

    let initData = JettonWalletData{
        balance: 0,
        ownerAddress,
        jettonMasterAddress,
        jettonWalletCode,
    };

    return contractAddress(StateInit{
        code: jettonWalletCode,
        data: initData.toCell(),
    });
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

/// https://docs.dedust.io/reference/tlb-schemes#message-swap-1
message(0xe3a0d482) JettonSwapPayload {
    // Inlined fields of SwapStep Struct
    poolAddress: Address;
    kind: Int as uint1 = 0;
    limit: Int as coins = 0;
    nextStep: SwapStep? = null;

    // Set of parameters relevant for the whole swap
    swapParams: SwapParams;
}

//
// Helper Structs described earlier on this page
//

struct SwapStep {
    poolAddress: Address;
    kind: Int as uint1 = 0;
    limit: Int as coins = 0;
    nextStep: Cell?;
}

struct SwapParams {
    deadline: Int as uint32 = 0;
    recipientAddress: Address? = null;
    referralAddress: Address? = null;
    fulfillPayload: Cell? = null;
    rejectPayload: Cell? = null;
}

//
// Messages from the Jetton standard
//

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell?; // slightly adjusted
}

struct MySendParameters {
    to: Address;
    value: Int as coins;
    body: Cell;
}

contract JettonReceive with Deployable {
    myJettonWalletAddress: Address;
    myJettonAmount: Int as coins = 0;

    init(jettonWalletCode: Cell, jettonMasterAddress: Address) {
        self.myJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            jettonMasterAddress,
            jettonWalletCode,
        );
    }

    receive(msg: JettonTransferNotification) {
        require(
            sender() == self.myJettonWalletAddress,
            "Notification not from your jetton wallet!",
        );

        self.myJettonAmount += msg.amount;

        if (!msg.forwardPayload.empty()) {
            // instead of deserializing it into JettonSwapPayload, 
            // we decided to just forward the payload as cell
            let dedustJettonSwapPayload: Cell = mySlice.loadRef();

            send(SendParameters{
                to: self.myJettonWalletAddress,
                value: myValue,
                body: dedustJettonSwapPayload,
            });
        }

        // Forward excesses
        self.forward(msg.sender, null, false, null);
    }

    get fun myJettonAmount(): Int {
        return self.myJettonAmount;
    }

    get fun myJettonWalletAddress(): Address {
        return self.myJettonWalletAddress;
    }
}
