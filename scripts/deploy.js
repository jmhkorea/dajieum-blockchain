// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  console.log("Deploying DaJeum Blockchain Prototype contracts...");

  // 1. 이름 데이터 컨트랙트 배포
  const DaJeumNaming = await hre.ethers.getContractFactory("DaJeumNaming");
  const naming = await DaJeumNaming.deploy();
  await naming.waitForDeployment();
  const namingAddress = await naming.getAddress();
  console.log(`DaJeumNaming deployed to: ${namingAddress}`);

  // 2. NFT 인증서 컨트랙트 배포
  const DaJeumNFT = await hre.ethers.getContractFactory("DaJeumNFT");
  const nft = await DaJeumNFT.deploy(namingAddress);
  await nft.waitForDeployment();
  const nftAddress = await nft.getAddress();
  console.log(`DaJeumNFT deployed to: ${nftAddress}`);

  // 3. 플랫폼 토큰 컨트랙트 배포 (초기 발행량: 1,000,000)
  const initialSupply = 1000000;
  const DaJeumToken = await hre.ethers.getContractFactory("DaJeumToken");
  const token = await DaJeumToken.deploy(initialSupply);
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log(`DaJeumToken deployed to: ${tokenAddress}`);

  // 배포 정보 저장
  console.log("\nDeployment Summary:");
  console.log("====================");
  console.log(`DaJeumNaming: ${namingAddress}`);
  console.log(`DaJeumNFT: ${nftAddress}`);
  console.log(`DaJeumToken: ${tokenAddress}`);
  console.log("====================");

  // 배포 정보를 파일에 저장하는 코드는 실제 배포 시 추가할 수 있습니다
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
