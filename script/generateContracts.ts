import * as fs from "fs";
import * as path from "path";

const rootFolder = path.join(__dirname, '..');
const getAbi = (type: string) =>
    JSON.parse(fs.readFileSync(`${rootFolder}/out/${type}.sol/${type}.json`, "utf8")).abi;
const getBlob = (type: string, chainId: string) => 
    JSON.parse(fs.readFileSync(`${rootFolder}/broadcast/Deploy${type}.s.sol/${chainId}/run-latest.json`, "utf8"));

const contracts = ['Ticket'];

const frontendPath = path.join(__dirname, '../../theunit-frontend/crypto', 'contracts.json');
const currentVersion = '0.0.1';
let contractsJson: any;


if (fs.existsSync(frontendPath)) {
    contractsJson = {
        name: 'UNIT Contracts',
        version: currentVersion,
        contracts: {}
    };
} else {
    contractsJson = JSON.parse(fs.readFileSync(frontendPath, "utf8"));
}

const chainId = process.argv[3];
const resultContracts = contractsJson.contracts as any;

try {
    const contractNameToInfo: any = {};
    for (let i=0; i<contracts.length; i++) {
        const contractName = contracts[i];
        const deployInfo = getBlob(contractName, chainId);
        const transactions = deployInfo.transactions;
        for (let q=0; q<transactions.length; q++) {
            const transaction = transactions[q];
            const name = transaction.contractName;
            const abi = getAbi(name);
            contractNameToInfo[name] = {
                abi,
                address: transaction.contractAddress
            };
        }
    }
    resultContracts[chainId] = contractNameToInfo;
    fs.writeFileSync(frontendPath, JSON.stringify({
        ...contractsJson,
        version: currentVersion,
        contracts: resultContracts
    }));
} catch(e) {
    console.error('Generate contracts.json failed:', e);
}
