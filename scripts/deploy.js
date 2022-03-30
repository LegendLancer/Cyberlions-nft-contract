require('dotenv').config();
const updateEnv = require('./updateEnv.js');
const updateSiteConfig = require('./updateSiteConfig.js');

async function main() {
  const contractFactory = await ethers.getContractFactory("CyberLionz");

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const { HIDDEN_METADATA_CID, VOUCHER_SIGNER_PUBLIC_KEY } = process.env;
  
  const delayedRevealUri = `ipfs://${HIDDEN_METADATA_CID}`
  const paymentsReceiver = VOUCHER_SIGNER_PUBLIC_KEY

  const contract = await contractFactory.deploy(delayedRevealUri, paymentsReceiver)

  const envUpdate = {
    'CONTRACT_ADDRESS': contract.address
  }

  updateEnv(envUpdate)
  updateSiteConfig(contract.address)
      
  console.log("Contract deployed to address:", contract.address)
}
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })
  