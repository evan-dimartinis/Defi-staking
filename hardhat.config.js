require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')
require('solidity-coverage')
require('hardhat-gas-reporter')
require('dotenv')

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0 //etheres built in accounts at index 0
    }
  }
};
