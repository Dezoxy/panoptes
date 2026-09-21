// People who use or operate Panoptes. The base keeps people and external systems
// in one fragment (people-systems.dsl); they are split here because Panoptes has
// more of both and the two lists change for different reasons.

engineer = person "Engineer" "Builds workloads that call models through the gateway. Owns the workload, not the platform."
businessUser = person "Business user" "Uses assistants built on the platform and the administered Copilot surfaces. Does not hold a gateway key."
platformOperator = person "Platform operator" "The AI Platform function. Runs the gateway, the controls plane and the lifecycle." "Staff"
securityReviewer = person "Security reviewer" "Approves classification and entitlement rules, and reads the evidence a control produced." "Staff"
finopsAnalyst = person "FinOps analyst" "Sets budgets per consumer and challenges spend that is not attributed." "Staff"
