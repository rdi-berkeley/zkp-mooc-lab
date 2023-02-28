const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("LeftShift", () => {
    var circ_file = path.join(__dirname, "circuits", "left_shift.circom");
    var circ, num_constraints;

    before(async () => {
        circ = await wasm_tester(circ_file);
        await circ.loadConstraints();
        num_constraints = circ.constraints.length;
        var shift_bnd = 25;
        var expected_constraints = shift_bnd + 2;
        console.log("LeftShift #Constraints:", num_constraints, "Expected:", expected_constraints);
        if (num_constraints < expected_constraints) {
            console.log("WARNING: number of constraints is less than shift_bound + 2. It is likely that you are not constraining the witnesses appropriately.");
        }
    });

    it("should pass test 1 - don't skip checks", async () => {
        const input = {
            "x": "65",
            "shift": "24",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"y": "1090519040"});
    });

    it("should pass test 2 - don't skip checks", async () => {
        const input = {
            "x": "65",
            "shift": "0",
            "skip_checks": "0",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"y": "65"});
    });

    it("should fail - don't skip checks", async () => {
        const input = {
            "x": "65",
            "shift": "25",
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

    it("should pass when `skip_checks` = 1 and `shift` is >= shift_bnd", async () => {
        const input = {
            "x": "65",
            "shift": "25",
            "skip_checks": "1",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
    });
});