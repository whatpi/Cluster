const { ethers } = require("hardhat");

async function main() {
  /* ────────── 계정 확인 ────────── */
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const System = await ethers.getContractFactory("MainSystem");
  const system = await System.deploy();
  await system.waitForDeployment();
  console.log("MainSystem:", await system.getAddress());

  system.on("ClusterCreated", (id, clusterAddr, creator, event) => {
  console.log("ClusterCreated fired:", { id, clusterAddr, creator });
  });

  const policy = ethers.encodeBytes32String("sample");
  const tx = await system.createCluster(0, policy, { value: ethers.parseEther("1") } );
  const receipt = await tx.wait();

  console.log("Tx Hash:", tx.hash);
  console.log("Cluster Gas Used:", receipt.gasUsed.toString());

  const digest = ethers.encodeBytes32String("sample");
  const tx2 = await system.createTopic(digest);
  console.log(tx);
// 트랜잭션 영수증까지는 기존과 동일
const receipt2 = await tx2.wait();

for (const log of receipt2.logs) {
  // (선택) 메인 시스템 계약에서 나온 로그만 처리
  if (log.address !== system.target) continue;

  const parsed = system.interface.parseLog(log);
  if (parsed === null) continue;              // v6: 매칭 실패 시 null

  if (parsed.name === "TopicCreated") {
    const { id: topicId, proxyAddr: topicProxyAddress } = parsed.args;
    console.log("TopicCreated:");
    console.log("  id           =", topicId.toString());
    console.log("  proxy address=", topicProxyAddress);
  }
}



  // main 함수 맨 끝에 추가
  console.log("리스너가 활성화되었습니다. Ctrl+C로 종료하세요.");
  await new Promise(() => {}); // 프로세스 유지
 
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
