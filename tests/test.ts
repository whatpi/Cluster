const { ethers } = require("hardhat");
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect }     from "chai";

describe ("debug", function() {

  async function deployFicture() {
    const [deployer, alice, bob] = await ethers.getSigners();

    
  }
  
});

async function main() {
  /* ────────── 계정 확인 ────────── */
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const System = await ethers.getContractFactory("MainSystem");
  const system = await System.deploy();
  await system.waitForDeployment();
  console.log("MainSystem:", await system.getAddress());

  // @account-abstraction/contracts 안에 EntryPoint.sol 구현이 포함되어 있습니다
  const EntryPoint = await ethers.getContractFactory("EntryPoint");
  const entryPoint = await EntryPoint.deploy();
  await entryPoint.waitForDeployment();


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


// // test/main-cluster.spec.ts
// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
// import { expect }     from "chai";
// const { ethers } = require("hardhat");
// import { EventLog } from "ethers";

// describe("MainSystem <-> ClusterSystem end-to-end debug", function () {

//   /* ──────────────────────────────
//      공동으로 쓰일 픽스처 설정
//      ────────────────────────────── */
//   async function deployFixture() {
//     /* 1) 배포자, 일반 사용자 2명 지정 */
//     const [deployer, alice, bob] = await ethers.getSigners();

//     /* 2) 외부 의존 컨트랙트(TopicFactory, EntryPoint 등) 선행 배포 */
//     const EntryPoint      = await ethers.getContractFactory("EntryPoint");
//     const entryPoint      = await EntryPoint.deploy();           // 실제 account-abstraction 구현체
//     await entryPoint.waitForDeployment();

//     const TopicFactory    = await ethers.getContractFactory("TopicFactory");
//     const topicFactory    = await TopicFactory.deploy(
//                               await deployer.getAddress(),       // dummy main address
//                               ethers.ZeroAddress                // dummy claimNFT address
//                             );
//     await topicFactory.waitForDeployment();

//     /* 3) MainSystem 배포 (앞서 수정한 버전) */
//     const MainSystem      = await ethers.getContractFactory("MainSystem");
//     const system      = await MainSystem.deploy(
//                               await topicFactory.getAddress(),
//                               await entryPoint.getAddress()
//                             );
//     await system.waitForDeployment();

//     /* TopicFactory에 MainSystem 주소 갱신 (constructor에서 setter 미리 열어 두었다고 가정) */
//     await topicFactory.setMainSystem(await system.getAddress());

//     console.log(await topicFactory.getAddress(), 1);
//     console.log(await system.getAddress(), 2);
//     console.log(await entryPoint.getAddress(), 3);


//     /* 4) 리턴. 이후 테스트 케이스에서 구조분해할 변수들 모아 두기 */
//     return { deployer, alice, bob, entryPoint, topicFactory, system };
//   }

//   /* ──────────────────────────────
//      1. 클러스터 생성
//      ────────────────────────────── */
//   it("creates cluster and records mapping", async function () {

//     const { alice, system } = await loadFixture(deployFixture);

//     /* 정책 다이제스트(dummy) 준비 */
//     const policyDigest = ethers.keccak256(ethers.toUtf8Bytes("initial-policy"));

//     /* alice가 클러스터 생성 (0.003ETH 예치) */
//     const tx = await system
//       .connect(alice)
//       .createCluster(policyDigest, { value: ethers.parseEther("0.003") });

//     const receipt = await tx.wait();

//     for (const log of receipt.logs) {
//         // (선택) 메인 시스템 계약에서 나온 로그만 처리
//         if (log.address !== system.target) continue;

//         const parsed = system.interface.parseLog(log);
//         if (parsed === null) continue;              // v6: 매칭 실패 시 null

//         if (parsed.name === "ClusterCreated") {
//             const { id: id, clusterAddress: clusterAddr,  user} = parsed.args;
//             console.log("TopicCreated:");
//             console.log("  id           =", id.toString());
//             console.log("  proxy address=", clusterAddr);

//             /* 매핑 검사 */
//             expect(await system.clusterIdToAddrs(id)).to.equal(clusterAddr);
//             expect(await system.addressToClusterId(clusterAddr)).to.equal(id);
//         }
//     }
    

//   });

//   /* ──────────────────────────────
//      2. 권한 부여 (Verified, Moderator)
//      ────────────────────────────── */
//   it("grants roles to members", async function () {
//     const { alice, bob, system } = await loadFixture(deployFixture);

//     /* 1단계: 클러스터 먼저 생성 */
//     const digest = ethers.keccak256(ethers.toUtf8Bytes("policy"));
//     const tx  = await system.connect(alice)
//                   .createCluster(digest, { value: ethers.parseEther("0.003") });
//     const receipt  = await tx.wait();

    

//     const Cluster     = await ethers.getContractAt("ClusterSystem", clusterAddr);

//     /* 2단계: bob이 join() 호출로 Member 획득 */
//     await Cluster.connect(bob).join();
//     expect(await Cluster.isMember(await bob.getAddress())).to.equal(true);

//     /* 3단계: alice(리더)가 bob을 Verified/Moderator로 승격 */
//     await Cluster.connect(alice).mintVerified(await bob.getAddress());
//     await Cluster.connect(alice).mintModerator(await bob.getAddress());

//     expect(await Cluster.isVerified(await bob.getAddress())).to.equal(true);
//     expect(await Cluster.isModerator(await bob.getAddress())).to.equal(true);
//   });

//   /* ──────────────────────────────
//      3. 차단 및 해제
//      ────────────────────────────── */
//   it("blocks and unblocks a user", async function () {
//     const { alice, bob, system } = await loadFixture(deployFixture);

//     /* 클러스터 준비 */
//     const digest = ethers.keccak256(ethers.toUtf8Bytes("policy"));
//     const cr   = await system.connect(alice)
//                   .createCluster(digest, { value: ethers.parseEther("0.003") });
    
//     const receipt = await cr.wait()

//     const ev = receipt.events?.find((e: EventLog | null): e is EventLog => !!e && e.eventName === "ClusterCreated");

//     if (!ev) throw new Error("ClusterCreated not emitted");

//     const [id, clusterAddr, user] = ev.args as [bigint, string, string];

//     const cluster = await ethers.getContractAt("ClusterSystem", clusterAddr);

//     /* bob 멤버 등록 및 Verified */
//     await cluster.connect(bob).join();
//     await cluster.connect(alice).mintVerified(await bob.getAddress());

//     /* 1) 차단 => isBlocked = true, 권한 소멸 */
//     await cluster.connect(alice).blockMemberOrVerified(await bob.getAddress());
//     expect(await cluster.isBlocked(await bob.getAddress())).to.equal(true);
//     expect(await cluster.isMember(await bob.getAddress())).to.equal(false);
//     expect(await cluster.isVerified(await bob.getAddress())).to.equal(false);

//     /* 2) 차단 해제 */
//     await cluster.connect(alice).unblock(await bob.getAddress());
//     expect(await cluster.isBlocked(await bob.getAddress())).to.equal(false);
//   });

//   /* ──────────────────────────────
//      4. Paymaster 가스 회수 시뮬레이션
//      ────────────────────────────── */
//   it("reserves and finalizes gas cost via Paymaster", async function () {
//     const { alice, system } = await loadFixture(deployFixture);

//     /* 클러스터 생성(보증금 0.005 ether로 넉넉히) */
//     const tx  = await system.connect(alice).createCluster(
//                    ethers.keccak256(ethers.toUtf8Bytes("policy")),
//                    { value: ethers.parseEther("0.005") }
//                  );
//     const receipt = await tx.wait();
//     const ev = receipt.events?.find((e: EventLog | null): e is EventLog => !!e && e.eventName === "ClusterCreated");

//     if (!ev) throw new Error("ClusterCreated not emitted");

//     const [dummy, clusterAddress, dummmmy] = ev.args as [bigint, string, string];


//     const cluster    = await ethers.getContractAt("ClusterSystem", clusterAddress);
//     const paymaster  = await ethers.getContractAt("ClusterPaymaster", await cluster.paymasterAddr());

//     /* Step-1: Paymaster가 0.001 ether 잠금(reserveGas) */
//     const reserveWei = ethers.parseEther("0.001");
//     await paymaster.connect(alice).reserveGasOnBehalf(cluster.target, reserveWei);
//     /* reserveGasOnBehalf는 ClusterPaymaster 내부에 만든 helper 함수라고 가정 */

//     /* Step-2: 실제 가스비 0.0007 ether 청구 후 차액 반환 */
//     const costWei    = ethers.parseEther("0.0007");
//     await paymaster.connect(alice).finalizeGasOnBehalf(
//       cluster.target,
//       reserveWei,
//       costWei
//     );

//     /* ClusterSystem.deposit가 정확히 차감되었는지 확인 (≈ 0.005-0.0007) */
//     const remain = await cluster.deposit();
//     expect(remain).to.equal(ethers.parseEther("0.0043"));
//   });

//   it("dummy", () => {
//     expect(true).to.equal(true);
//   });

// });
