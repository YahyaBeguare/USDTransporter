const {hre}= require("hardhat");
const fs = require("fs");
const path = require("path");   
const addressFile = require("../address.json");
let contractAddress ;

async function deploy(){
    try{
    const usdcTransporter= await hre.ethers.deployContract("USDTransporter");
    await usdcTransporter.waitForDeployement();
    contractAddress = usdcTransporter.target;
    console.log("Contract deployed to:", contractAddress); 

}  catch(error){
    console.error("error Deploying USDCTransporter ",error);
}

try {
    addressFile["USDCTransporter"][
      "ContractAddess"
    ] = contractAddress;
    fs.writeFile("./address.json", JSON.stringify(addressFile, null, 2));
  } catch (err) {
    console.error("Error: ", err);
  }

}

deploy()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });