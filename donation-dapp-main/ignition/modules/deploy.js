import hre from "hardhat";
const { ethers } = hre;

async function main() {
  // 👇 DANH SÁCH CÁC VÍ SẼ LÀM CHỦ SỞ HỮU (Thay bằng ví thật của bạn)
  const owners = [
      "0x59500a0BcE501Fe08044fB5B63B933F792d0e32e", 
      "0x309b1aFA57F7b279beECa3E1fD5Aa2307e5bd3eF", 
      "0xDBeAA7FE31285ABa445a54d2522eC08474826144"  
  ];
  const requiredApprovals = 2; // Cần ít nhất 2 người đồng ý mới được rút

  console.log("Deploying DonationDApp with Multi-Sig...");
  const DonationDApp = await ethers.getContractFactory("DonationDApp");
  
  // Truyền tham số vào constructor
  const donation = await DonationDApp.deploy(owners, requiredApprovals);

  await donation.waitForDeployment();

  console.log(`DonationDApp deployed to: ${donation.target}`);
  console.log(`Owners: ${owners}`);
  console.log(`Required Approvals: ${requiredApprovals}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});