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
            // msg.sender is actual sender i guess
            sender() == self.myJettonWalletAddress,
            "Notification not from your jetton wallet!",
        );

        self.myJettonAmount += msg.amount;

        if (!msg.forwardPayload.empty()) {
            // instead of deserializing it into JettonSwapPayload, 
            // we decided to just forward the payload as cell
            let dedustJettonSwapPayload: Cell = msg.forwardPayload.loadRef();

            send(SendParameters{
                to: self.myJettonWalletAddress,
                value: ton("0.5"),
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
