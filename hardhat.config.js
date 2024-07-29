require("@nomicfoundation/hardhat-toolbox");



/** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.24",
// };

// require("@nomicfoundation/hardhat-toolbox");
// require('@nomiclabs/hardhat-ethers');
// require('@nomiclabs/hardhat-waffle');

// 
const PRIVATE_KEY = '';

module.exports = {
    solidity: "0.8.20",
    // solidity: "0.8.15",
    networks: {
        coston: {
            url: 'https://coston-api.flare.network/ext/bc/C/rpc',
            // url: 'https://coston-testnet.flare.network/ext/bc/C/rpc',
            // url: 'https://coston.flare.network/ext/bc/C/rpc',
            accounts: [`0x${PRIVATE_KEY}`],
            // timeout: 200000000, // Increase timeout to 200 seconds
        }, 
        coston2: {
          url: 'https://coston2-api.flare.network/ext/bc/C/rpc',
          accounts: [`0x${PRIVATE_KEY}`]
      }
    }
};