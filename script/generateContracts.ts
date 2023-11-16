import * as fs from "fs";
import * as path from "path";

const rootFolder = path.join(__dirname, '..');
const getAbi = (type: string) =>
    JSON.parse(fs.readFileSync(`${rootFolder}/out/${type}.sol/${type}.json`, "utf8")).abi;
const getBlob = (type: string, chainId: string) => 
    JSON.parse(fs.readFileSync(`${rootFolder}/broadcast/Deploy${type}.s.sol/${chainId}/run-latest.json`, "utf8"));

const supportedChains = [421613]
// const contracts = ['Token', 'Farm', 'Vault'];
const contracts = ['Token'];
const result: any = {};

try {
    for (let i=0; i<contracts.length; i++) {
        const contractName = contracts[i];
        for (let j=0; j<supportedChains.length; j++) {
            const chainId = supportedChains[j].toString();
            const deployInfo = getBlob(contractName, chainId);
            const transactions = deployInfo.transactions;
            for (let q=0; q<transactions.length; q++) {
                const transaction = transactions[q];
                const name = transaction.contractName;
                if (j == 0) {
                    result[name] = { 
                        abi: getAbi(name), 
                        deployments: {} 
                    };
                }
                result[name]["deployments"][chainId] = transaction.contractAddress;
    
            }
        }
    }
} catch(e) {
    console.error('Generate contracts.json failed:', e);
}

fs.writeFile(path.join(__dirname, '../../theunit-frontend/crypto', 'contracts.json'), JSON.stringify(result), (err) => {
    if (err) {
      console.error(err);
      return;
    }
});