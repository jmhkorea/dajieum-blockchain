// scripts/test-deployment.js
const hre = require("hardhat");

async function main() {
  console.log("Testing DaJeum Blockchain Prototype deployment...");

  // 컨트랙트 주소 설정 (실제 배포 후 업데이트 필요)
  const namingAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // 예시 주소
  const nftAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";     // 예시 주소
  const tokenAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";   // 예시 주소

  // 컨트랙트 인스턴스 가져오기
  const naming = await hre.ethers.getContractAt("DaJeumNaming", namingAddress);
  const nft = await hre.ethers.getContractAt("DaJeumNFT", nftAddress);
  const token = await hre.ethers.getContractAt("DaJeumToken", tokenAddress);

  // 1. 이름 등록 테스트
  console.log("\n1. 이름 등록 테스트");
  console.log("---------------------");
  const tx1 = await naming.registerName("김민준", 2020, 5, 15, "남");
  const receipt1 = await tx1.wait();
  const nameId = receipt1.logs[0].args[0];
  console.log(`이름 등록 완료: ID=${nameId}, 이름=김민준`);

  // 2. 이름 조회 테스트
  console.log("\n2. 이름 조회 테스트");
  console.log("---------------------");
  const nameData = await naming.getNameById(nameId);
  console.log(`이름 조회 결과: ${nameData.fullName}, ${nameData.birthYear}년 ${nameData.birthMonth}월 ${nameData.birthDay}일, ${nameData.gender}`);

  // 3. NFT 인증서 발행 테스트
  console.log("\n3. NFT 인증서 발행 테스트");
  console.log("---------------------------");
  const [owner] = await hre.ethers.getSigners();
  const tokenURI = "ipfs://QmExample123456789";
  const imageURI = "ipfs://QmExampleImage123456789";
  const tx2 = await nft.mintCertificate(owner.address, nameId, tokenURI, imageURI);
  const receipt2 = await tx2.wait();
  const tokenId = receipt2.logs[0].args[0];
  console.log(`NFT 인증서 발행 완료: TokenID=${tokenId}, NameID=${nameId}`);

  // 4. NFT 메타데이터 조회 테스트
  console.log("\n4. NFT 메타데이터 조회 테스트");
  console.log("-------------------------------");
  const metadata = await nft.getCertificateMetadata(tokenId);
  console.log(`NFT 메타데이터: NameID=${metadata.nameId}, ImageURI=${metadata.imageURI}`);

  // 5. 토큰 잔액 조회 테스트
  console.log("\n5. 토큰 잔액 조회 테스트");
  console.log("---------------------------");
  const balance = await token.balanceOf(owner.address);
  console.log(`토큰 잔액: ${hre.ethers.formatEther(balance)} DJM`);

  // 6. 서비스 이용료 지불 테스트
  console.log("\n6. 서비스 이용료 지불 테스트");
  console.log("-------------------------------");
  const servicePrice = await token.getServicePrice("naming");
  console.log(`작명 서비스 가격: ${hre.ethers.formatEther(servicePrice)} DJM`);
  const tx3 = await token.payForService("naming");
  await tx3.wait();
  console.log("서비스 이용료 지불 완료");

  // 7. 배치 이름 등록 테스트
  console.log("\n7. 배치 이름 등록 테스트");
  console.log("---------------------------");
  const names = ["이서연", "박지호", "최수아"];
  const years = [2019, 2021, 2022];
  const months = [3, 7, 11];
  const days = [10, 22, 5];
  const genders = ["여", "남", "여"];
  const tx4 = await naming.batchRegisterNames(names, years, months, days, genders);
  const receipt4 = await tx4.wait();
  const [startId, endId] = [receipt4.logs[0].args[0], receipt4.logs[0].args[1]];
  console.log(`배치 이름 등록 완료: StartID=${startId}, EndID=${endId}`);

  console.log("\n테스트 완료!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
