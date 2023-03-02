const exp = require("constants");
const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("MSNZB", () => {
    var circ_file = path.join(__dirname, "circuits", "msnzb.circom");
    var circ;
    var num_constraints;

    before(async () => {
        circ = await wasm_tester(circ_file);
        await circ.loadConstraints();
        num_constraints = circ.constraints.length;
        var b = 48;
        var expected_constraints = 3*b - 1;
        console.log("MSNZB #Constraints:", num_constraints, "Expected:", expected_constraints);
        if (num_constraints < expected_constraints) {
            console.log("WARNING: number of constraints is less than 3b-1. It is likely that you are not constraining the witnesses appropriately.");
        }
    });

    it("should pass test 1 - don't skip checks", async () => {
        const input = {
            "in": "1",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"one_hot": ["1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"]});
    });

    it("should pass test 2 - don't skip checks", async () => {
        const input = {
            "in": "281474976710655",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"one_hot": ["0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1"]});
    });

    it("should fail when `in` = 0 - don't skip checks", async () => {
        const input = {
            "in": "0",
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

    it("should pass when `skip_checks` = 1 and `in` is 0", async () => {
        const input = {
            "in": "0",
            "skip_checks": "1",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
    });
});
