const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  
  describe("Fill data", function () {

    async function deployOneYearLockFixture() {
      // Contracts are deployed using the first signer/account by default
      const [owner, otherAccount] = await ethers.getSigners();
  
        const BridgePixelToken = await ethers.getContractFactory("BridgePixelToken");
        const BridgePixel = await ethers.getContractFactory("BridgePixel");

        // coston
        let costonBridgePixelTokenAddress =  "";
        let costonBridgePixelAddress =  "";

        // coston2
        let coston2BridgePixelAddress =  "";
        let coston2BridgePixelTokenAddress =  "";

        // const providerCoston = new ethers.providers.JsonRpcProvider("https://coston-api.flare.network/ext/bc/C/rpc");
        // const providerCoston2 = new ethers.providers.JsonRpcProvider("https://coston2-api.flare.network/ext/bc/C/rpc");

        const bridgePixelToken = BridgePixelToken.attach(costonBridgePixelTokenAddress);
        const bridgePixel = BridgePixel.attach(costonBridgePixelAddress);


        // _pixelBridgeToken
        // _oppositePixelBridgeToken
        // _price (fee)
        // _attestationType
        // _sourceId
        // _sourceId opposite
        // _requiredConfirmation 
        // _oppositePixelBridgeContract
        // _stateConnector
        // _oppositeBridge
        // currentLowestUsedTimestamp
        // console.log("1111");


        // let tx = await bridgePixel.SetPixelBridgeToken("0xF18DA3554D9205561D3E2EdD0695C560c9052cD7");
        // await tx.wait();
        
        console.log("2222");

        // let network11 = await ethers.getDefaultProvider().getNetwork();
        // console.log("Network name=", network11.name);
        // console.log("Network chain id=", network11.chainId);


        let _pixelBridgeToken = await bridgePixel.pixelBridgeToken();
        console.log("_pixelBridgeToken = ", _pixelBridgeToken);

        // let tx = await bridgePixel.SetFeeBridge(100);
        // await tx.wait();

        let fee = await bridgePixel.fee();
        console.log("fee = ", Number(fee) / 10000);

        // let tx = await bridgePixel.SetAttestationTypeEVM("0x45564d5472616e73616374696f6e000000000000000000000000000000000000");
        // await tx.wait();

        let attestationTypeEVM = await bridgePixel.attestationTypeEVM();
        console.log("attestationTypeEVM = ", attestationTypeEVM);

        // let tx = await bridgePixel.SetOppositeSourceId("0x4332464c52000000000000000000000000000000000000000000000000000000");
        // await tx.wait();

        let oppositeSourseID = await bridgePixel.oppositeSourseID();
        console.log("oppositeSourseID = ", oppositeSourseID);

        // let tx = await bridgePixel.SetRequiredConfirmation(1);
        // await tx.wait();

        let oppositeRequiredConfirmation = await bridgePixel.oppositeRequiredConfirmation();
        console.log("oppositeRequiredConfirmation = ", Number(oppositeRequiredConfirmation));

        // let tx = await bridgePixel.SetOppositePixelBridgeContract("0x500e4b57e129B30649d8490e41dF616C59FC7632");
        // await tx.wait();

        let oppositePixelBridgeContract = await bridgePixel.oppositePixelBridgeContract();
        console.log("oppositePixelBridgeContract = ", oppositePixelBridgeContract);

        // let tx = await bridgePixel.SetStateConnectorAddress("0x0c13aDA1C7143Cf0a0795FFaB93eEBb6FAD6e4e3");
        // await tx.wait();

        let stateConnector = await bridgePixel.stateConnector();
        console.log("stateConnector = ", stateConnector);

        // 
        // let tx = await bridgePixel.SetCurrentLowestUsedTimestamp(BigInt(1696806248));
        // await tx.wait();

        let currentLowestUsedTimestamp = await bridgePixel.currentLowestUsedTimestamp();
        console.log("currentLowestUsedTimestamp = ", currentLowestUsedTimestamp);


  
    //   return { lock, unlockTime, lockedAmount, owner, otherAccount };
        return { owner };
    }
  
    describe("Deployment", function () {
      it("Should set params", async function () {
        const { owner } = await loadFixture(deployOneYearLockFixture);
  
        expect("0").to.equal("0");
      });
  
    });
  });
  