const { expect } = require("chai");
const { name, mintPrice, collectionSize, contractName } = require('../siteConfig.json').smartContract

describe(name, function () {

    let Token;
    let smartContract;
    let owner;

    beforeEach(async function () {
        Token = await ethers.getContractFactory(contractName);
        [owner, user1] = await ethers.getSigners();
        
        smartContract = await Token.deploy('ipfs://', owner.address);

    })

    describe("Deployment", function () {
        it("Deployment should set default values", async function () {
        
            const TOKEN_PRICE = await smartContract.MINT_PRICE();
            const COLLECTION_SIZE = await smartContract.COLLECTION_SIZE();

            expect((ethers.utils.formatUnits(TOKEN_PRICE)).toString()).to.equal(mintPrice.toString());
            expect(+COLLECTION_SIZE).to.equal(collectionSize);
        })
    })

    describe("Functions", function () {
        it("mint the NFT", async function () {

            let txResponse;
            const TOKEN_PRICE = await smartContract.MINT_PRICE();
            const total = 2 * TOKEN_PRICE;
            const value = ethers.utils.parseEther(total.toString())
            console.log('value: ', value);

            txResponse = await smartContract.connect(user1).mint(2, {
                value
            });
            expect(await smartContract._mintedCount(user1.address)).to.be.equal(2);
        })
    })
    
});