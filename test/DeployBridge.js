const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  
  describe("Deployment", function () {

    async function deployOneYearLockFixture() {
    //   const ONE_GWEI = 1_000_000_000;
  

      // Contracts are deployed using the first signer/account by default
      const [owner, otherAccount] = await ethers.getSigners();
  

        const BridgePixelToken = await ethers.getContractFactory("BridgePixelToken");
        const BridgePixel = await ethers.getContractFactory("BridgePixel");

        let nameBridgeOnFlare = "Pixel bridge on Flare";
        let nameBridgeOnSongbird = "Pixel bridge on Songbird";

        const bridgePixel = await BridgePixel.deploy(nameBridgeOnSongbird);
        // await bridgePixel.deployed();
        // await bridgePixel.deployTransaction.wait();
        await bridgePixel.waitForDeployment();

        let nameOnFlare = "pixelSGB";
        let nameOnSongbird = "pixelFLr";

        let symbolOnFlare = "pSGB";
        let symbolOnSongbird = "pFLr";

        console.log("bridgePixel.address = ", bridgePixel.target);
        console.log("owner = ", owner);
        

        const bridgePixelToken = await BridgePixelToken.deploy(nameOnSongbird, symbolOnSongbird, bridgePixel.target);
        await bridgePixelToken.waitForDeployment();

        console.log("bridgePixelToken.address = ", bridgePixelToken.target);
        

        console.log("success");
        // coston
        // bridgePixelToken.address =  0xF18DA3554D9205561D3E2EdD0695C560c9052cD7
        // bridgePixel.address =  0x97a23C81D5839b917e8a9FB371cf4413001B9E17

        // coston2
        // bridgePixel.address =  0x500e4b57e129B30649d8490e41dF616C59FC7632
        // bridgePixelToken.address =  0x777a363875930ee6Ac5DF9CB6C3dE7BE23975187



  
    //   return { lock, unlockTime, lockedAmount, owner, otherAccount };
    return { owner };
    }
  
    describe("Deployment", function () {
      it("Should set the right unlockTime", async function () {
        const { owner } = await loadFixture(deployOneYearLockFixture);
  
        expect("0").to.equal("0");
      });
  
    //   it("Should set the right owner", async function () {
    //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  
    //     expect(await lock.owner()).to.equal(owner.address);
    //   });
  
    //   it("Should receive and store the funds to lock", async function () {
    //     const { lock, lockedAmount } = await loadFixture(
    //       deployOneYearLockFixture
    //     );
  
    //     expect(await ethers.provider.getBalance(lock.target)).to.equal(
    //       lockedAmount
    //     );
    //   });
  
    //   it("Should fail if the unlockTime is not in the future", async function () {
    //     // We don't use the fixture here because we want a different deployment
    //     const latestTime = await time.latest();
    //     const Lock = await ethers.getContractFactory("Lock");
    //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //       "Unlock time should be in the future"
    //     );
    //   });
    // });
  
    // describe("Withdrawals", function () {
    //   describe("Validations", function () {
    //     it("Should revert with the right error if called too soon", async function () {
    //       const { lock } = await loadFixture(deployOneYearLockFixture);
  
    //       await expect(lock.withdraw()).to.be.revertedWith(
    //         "You can't withdraw yet"
    //       );
    //     });
  
    //     it("Should revert with the right error if called from another account", async function () {
    //       const { lock, unlockTime, otherAccount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       // We can increase the time in Hardhat Network
    //       await time.increaseTo(unlockTime);
  
    //       // We use lock.connect() to send a transaction from another account
    //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
    //         "You aren't the owner"
    //       );
    //     });
  
    //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
    //       const { lock, unlockTime } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       // Transactions are sent using the first signer by default
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw()).not.to.be.reverted;
    //     });
    //   });
  
    //   describe("Events", function () {
    //     it("Should emit an event on withdrawals", async function () {
    //       const { lock, unlockTime, lockedAmount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw())
    //         .to.emit(lock, "Withdrawal")
    //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
    //     });
    //   });
  
    //   describe("Transfers", function () {
    //     it("Should transfer the funds to the owner", async function () {
    //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw()).to.changeEtherBalances(
    //         [owner, lock],
    //         [lockedAmount, -lockedAmount]
    //       );
    //     });
    //   });
    });
  });
  