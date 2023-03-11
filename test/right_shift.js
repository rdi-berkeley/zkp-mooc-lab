const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("RightShift", () => {
    var circ_file = path.join(__dirname, "circuits", "right_shift.circom");
    var circ, num_constraints;

    before(async () => {
        circ = await wasm_tester(circ_file);
        await circ.loadConstraints();
        num_constraints = circ.constraints.length;
        var b = 49;
        var expected_constraints = b;
        console.log("RightShift #Constraints:", num_constraints, "Expected:", b);
        if (num_constraints < expected_constraints) {
            console.log("WARNING: number of constraints is less than `b`. It is likely that you are not constraining the witnesses appropriately.");
        }
    });

    it("should pass - small bitwidth", async () => {
        const input = {
            "x": "82263136010365",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"y": "4903265"});
    });

    it("should fail - large bitwidth", async () => {
        const input = {
            "x": "15087340228765024367",
        };
        try {
            const witness = await circ.calculateWitness(input);
            await circ.checkConstraints(witness);
        } catch (e) {
            return 0;
        }
        assert.fail("should have thrown an error");
    });
});