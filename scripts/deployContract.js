const {hre, ethers}= require("hardhat");
const fs = require("fs");
const path = require("path");   
const addressFile = require("../address.json");
let contractAddress ;

async function deploy(){
    try{
    const usdcTransporter= await ethers.deployContract("USDCTransporter");
    await usdcTransporter.waitForDeployment();
    contractAddress =  usdcTransporter.target;
    console.log("Contract deployed to:", contractAddress); 

}  catch(error){
    console.error("error Deploying USDCTransporter ",error);
}

try {
    addressFile["USDCTransporter"] = {ContractAddess: contractAddress};
    fs.writeFileSync("./address.json", JSON.stringify(addressFile, null, 2));
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

