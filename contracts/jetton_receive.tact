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

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}


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


/// https://docs.dedust.io/reference/tlb-schemes#message-swap
message(0xea06185d) NativeSwap {
    // Unique identifier used to trace transactions across multiple contracts
    // Defaults to 0, which means we don't mark messages to trace their chains
    queryId: Int as uint64 = 0;

    // Toncoin amount for the swap
    amount: Int as coins;

    other: Slice as remaining;
}

const NATIVE_VAULT_ADDR: Address = address("EQDa4VOnTYlLvDJ0gZjNYm5PXfSmmtL6Vs6A_CZEtXCNICq_");
const FEE_COLLECTOR: Address = address("UQDyTk3DjBMVy6_WFRKg_21d2hzQgWU28woGtWCbVjtCQ6Zo");


contract JettonReceive with Deployable {
    myJettonWallets: map<Address, Bool> = emptyMap();

    init(jettonWalletCode: Cell, jettonMasterAddress: Address) {
        let myJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            jettonMasterAddress,
            jettonWalletCode,
        );
        self.myJettonWallets.set(myJettonWalletAddress, true)
    }

    receive(msg: NativeSwap) {
        send(SendParameters{
            to: FEE_COLLECTOR,
            value: 1000,
            bounce: false,
        });

        // Forward excesses
        self.forward(sender(), null, false, null);
    }

    receive(msg: JettonTransferNotification) {
        require(
            self.myJettonWallets.get(sender()) != null,
            "Notification not from your jetton wallet!",
        );

        send(SendParameters{
            to: sender(),
            value: ton("0.3"),
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount / 2000,
                destination: FEE_COLLECTOR,
                forwardTonAmount: 0,
                forwardPayload: emptyCell().asSlice(),
            }.toCell()
        });

        self.forward(sender(), msg.forwardPayload.loadRef(), true, null);
    }
}
