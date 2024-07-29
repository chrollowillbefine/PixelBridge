async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const BridgePixelToken = await ethers.getContractFactory("BridgePixelToken");
    const BridgePixel = await ethers.getContractFactory("BridgePixel");

    let nameBridgeOnFlare = "Pixel bridge on Flare";
    let nameBridgeOnSongbird = "Pixel bridge on Songbird";

    const bridgePixel = await BridgePixel.deploy(nameBridgeOnFlare);
    await bridgePixel.waitForDeployment();

    let nameOnFlare = "pixelSGB";
    let nameOnSongbird = "pixelFLr";

    let symbolOnFlare = "pSGB";
    let symbolOnSongbird = "pFLr";

    

    const bridgePixelToken = await BridgePixelToken.deploy(nameOnFlare, symbolOnFlare, bridgePixel.target);
    await bridgePixelToken.waitForDeployment();

    console.log("bridgePixel.address = ", bridgePixel.target);
    console.log("bridgePixelToken.address = ", bridgePixelToken.target);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
