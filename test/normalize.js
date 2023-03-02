const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("Normalize", () => {
    var circ_file = path.join(__dirname, "circuits", "normalize.circom");
    var circ_file_msnzb = path.join(__dirname, "circuits", "msnzb.circom");
    var circ, num_constraints;

    before(async () => {
        circ = await wasm_tester(circ_file);
        await circ.loadConstraints();
        num_constraints = circ.constraints.length;
        var k = 8, p = 23, P = 47;
        console.log("Normalize #Constraints:", num_constraints, "Expected:", 3*(P+1));

        circ_msnzb = await wasm_tester(circ_file_msnzb);
        await circ_msnzb.loadConstraints();
        num_constraints_msnzb = circ_msnzb.constraints.length;
        if (num_constraints < num_constraints_msnzb + 1) {
            console.log("WARNING: the #constraints is less than (#constraints for MSNZB + 1). It is likely that you are not constraining the witnesses appropriately.");
        }
    });

    it("should pass - don't skip checks", async () => {
        const input = {
            "e": "100",
            "m": "20565784002591",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"e_out": "121", "m_out": "164526272020728"});
    });

    it("should pass - already normalized and don't skip checks", async () => {
        const input = {
            "e": "100",
            "m": "164526272020728",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"e_out": "124", "m_out": "164526272020728"});
    });

    it("should fail when `m` = 0 - don't skip checks", async () => {
        const input = {
            "e": "100",
            "m": "0",
            "skip_checks": "0",
        };
        try {
            const witness = await circ.calculateWitness(input);
            await circ.checkConstraints(witness);
        } catch (e) {
            return 0;
        }
        assert.fail("should have thrown an error");
    });

    it("should pass when `skip_checks` = 1 and `m` is 0", async () => {
        const input = {
            "e": "100",
            "m": "0",
            "skip_checks": "1",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
    });
});
