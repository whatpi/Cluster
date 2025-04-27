const { ethers } = require("hardhat");

async function main() {
  /* ────────── 계정 확인 ────────── */
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  /* ────────── 1. TopicBoard ────────── */
  const Board = await ethers.getContractFactory("TopicBoard");
  const board = await Board.deploy();
  await board.waitForDeployment();
  console.log("TopicBoard:", board.target);

  /* ────────── 2. MainSystem (보드 주소 주입) ────────── */
  const System = await ethers.getContractFactory("MainSystem");
  const system = await System.deploy(board.target);
  await system.waitForDeployment();
  console.log("MainSystem:", system.target);

  /* ────────── 선택 3. 첫 번째 클러스터 배포 ────────── */
  // 3-1) ClusterPass (ERC-1155)
  const ClusterPass = await ethers.getContractFactory("ClusterPass");
  const pass = await ClusterPass.deploy("");
  await pass.waitForDeployment();
  console.log("ClusterPass #1:", pass.target);

  /* 2️  ClusterSystem  ── 인자 9개 맞추기 */
  const Cluster = await ethers.getContractFactory("ClusterSystem");

  const clusterId      = 0;
  const sideCode       = 0;                              // Side.PRO
  const parentTopicId  = 0;
  const policyDigest   = ethers.ZeroHash;                // bytes32(0)
  const openingDigest  = ethers.ZeroHash;
  const depositWei     = ethers.parseEther("0");

  const cluster = await Cluster.deploy(
    clusterId,               // ①
    sideCode,                // ②  (enum은 uint8 캐스팅)
    deployer.address,        // ③
    parentTopicId,           // ④
    system.target,           // ⑤  mainSystemAddr
    pass.target,             // ⑥  passContractAddr
    policyDigest,            // ⑦
    openingDigest,           // ⑧
    depositWei               // ⑨
  );
  await cluster.waitForDeployment();

    /* 3️  소유권 이전 */
    await pass.transferOwnership(cluster.target);

    console.log("ClusterSystem:", cluster.target);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
