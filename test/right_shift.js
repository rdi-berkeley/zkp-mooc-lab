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
        var shift = 24;
        var expected_constraints = shift;
        console.log("RightShift #Constraints:", num_constraints, "Expected:", shift);
        if (num_constraints < expected_constraints) {
            console.log("WARNING: number of constraints is less than `shift`. It is likely that you are not constraining the witnesses appropriately.");
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

    it("should pass - large bitwidth", async () => {
        const input = {
            "x": "15087340228765024367",
        };
        const witness = await circ.calculateWitness(input);
        await circ.checkConstraints(witness);
        await circ.assertOut(witness, {"y": "899275554941"});
    });
});