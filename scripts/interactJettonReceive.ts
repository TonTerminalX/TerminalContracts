import { Address, toNano } from '@ton/core';
import { JettonReceive } from '../wrappers/JettonReceive';
import { NetworkProvider, sleep } from '@ton/blueprint';

export async function run(provider: NetworkProvider, args: string[]) {
    const ui = provider.ui();

    const address = Address.parse(`UQA80gmudfe3WfSok_5JXWEHNYHx9rvh7sdOtPrSYNTmpZE4`);

    if (!(await provider.isContractDeployed(address))) {
        ui.write(`Error: Contract at address ${address} is not deployed!`);
        return;
    }

    const simpleCounter = provider.open(JettonReceive.fromAddress(address));

    const jettonAmount = await simpleCounter.getMyJettonAmount();
    const jettonWalletAddress = await simpleCounter.getMyJettonWalletAddress();
    console.log(`Jetton amount: ${jettonAmount}`);
    console.log(`Jetton wallet address: ${jettonWalletAddress}`);

    // await simpleCounter.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'Add',
    //         queryId: 0n,
    //         amount: 1n,
    //     }
    // );

    ui.write('Waiting for counter to increase...');

    // let counterAfter = await simpleCounter.getMyJettonAmount();
    // let attempt = 1;
    // while (counterAfter === counterBefore) {
    //     ui.setActionPrompt(`Attempt ${attempt}`);
    //     await sleep(2000);
    //     counterAfter = await simpleCounter.getMyJettonAmount();
    //     attempt++;
    // }

    // ui.clearActionPrompt();
    // ui.write('Counter increased successfully!');
}
