import { Address, toNano } from '@ton/core';
import { JettonReceive } from '../wrappers/JettonReceive';
import { NetworkProvider, sleep } from '@ton/blueprint';

export async function run(provider: NetworkProvider, args: string[]) {
    const ui = provider.ui();

    const address = Address.parse(`EQA80gmudfe3WfSok_5JXWEHNYHx9rvh7sdOtPrSYNTmpcz9`);

    if (!(await provider.isContractDeployed(address))) {
        ui.write(`Error: Contract at address ${address} is not deployed!`);
        return;
    }

    const simpleCounter = provider.open(JettonReceive.fromAddress(address));

    const jettonAmount = await simpleCounter.getMyJettonAmount();
    const jettonWalletAddress = await simpleCounter.getMyJettonWalletAddress();
    console.log(`Jetton amount: ${jettonAmount}`);
    console.log(`Jetton wallet address: ${jettonWalletAddress}`);
}
