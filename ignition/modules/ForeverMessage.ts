import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ForeverMessageModule = buildModule("ForeverMessageModule", (m) => {
  const foreverMessage = m.contract("ForeverMessage");

  return { foreverMessage };
});

export default ForeverMessageModule;
