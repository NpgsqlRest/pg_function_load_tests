// Table scenario: see ../lib/table.js
import { tableScenario } from '../lib/table.js';

const scenario = tableScenario('insert');
export const options = scenario.options;
export default scenario.run;
export const handleSummary = scenario.handleSummary;
