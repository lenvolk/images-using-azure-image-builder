+------------------------------------------------------------------------------------------------+
| Azure Tenant / Management Group (Implied Highest Level)                                        |
|                                                                                                |
|   +------------------------------------------------------------------------------------------+ |
|   | **Azure Subscription**                                                                   |
|   |   (Contains AzPolicy-Test Resource Group)                                                |
|   |                                                                                          |
|   |   **Policy Assignment 1:**                                                               |
|   |   *   **Policy:** Allowed Locations                                                      |
|   |   *   **Scope:** Subscription                                                            |
|   |   *   **Effect:** Only allows deployment to **Australia East**                           |
|   |                                                                                          |
|   |   |                                                                                      |
|   |   |   (Inheritance: Policies flow down to child scopes)                                  |
|   |   V                                                                                      |
|   |                                                                                          |
|   |   +------------------------------------------------------------------------------------+ |
|   |   |   **Resource Group: AzPolicy-Test**                                              | |
|   |   |   (Located in Australia East)                                                      | |
|   |   |                                                                                    | |
|   |   |   **Policy Assignment 2:**                                                         | |
|   |   |   *   **Policy:** Allowed Locations (Same policy definition as above)              | |
|   |   |   *   **Scope:** Resource Group: AzPolicy-Test                                   | |
|   |   |   *   **Effect:** Denies deployment to **Australia East**                          | |
|   |   |   *   **Effect:** Allows deployment to **UK South**                                | |
|   |   |                                                                                    | |
|   |   |   **Combined Policy Evaluation for Resource Deployment within AzPolicy-Test RG:**  | |
|   |   |                                                                                    | |
|   |   |   *   **Attempt to deploy to Australia East:**                                     | |
|   |   |       - Subscription Policy: ALLOWS Australia East                                 | |
|   |   |       - Resource Group Policy: DENIES Australia East                               | |
|   |   |       - **RESULT: DENIED (Resource Group policy takes precedence)**                | |
|   |   |                                                                                    | |
|   |   |   *   **Attempt to deploy to UK South:**                                           | |
|   |   |       - Subscription Policy: (No explicit rule for UK South from this policy)      | |
|   |   |       - Resource Group Policy: ALLOWS UK South                                     | |
|   |   |       - **RESULT: ALLOWED**                                                        | |
|   |   |                                                                                    | |
|   |   |   *   **Attempt to deploy to any other region (e.g., East US):**                   | |
|   |   |       - Subscription Policy: Only ALLOWS Australia East                            | |
|   |   |       - Resource Group Policy: Only ALLOWS UK South (and DENIES Australia East)    | |
|   |   |       - **RESULT: DENIED (Not explicitly allowed by either policy in effect)**     | |
|   |   +------------------------------------------------------------------------------------+ |
|   +------------------------------------------------------------------------------------------+ |
+------------------------------------------------------------------------------------------------+