# Process & Collab Solution Template

  [Development Solution](#) 
• [Testing Solution](#)
• [Production Solution](#)

![Check and deploy to testing](../../actions/workflows/check-test.yml/badge.svg)

This is a repository template for Process & Collab solutions. Use it for a quickstart on setting up Git version control with a new Power Platform solution.

For more template-related information, see the [Template App](https://github.com/niaid/proc-collab-hub/wiki/Template-App) page in the P&C docs.

## User Roles

Role | Purpose
---- | -------
Role1 | Role1 purpose.
Role2 | Role2 purpose.
RoleN | RoleN purpose.

## Workflow

I recommend [flowchart.fun](https://flowchart.fun) for sketching small workflow diagrams. You can upload the image to a draft GitHub issue to get a link without actually creating the issue. (You can also include the FF markup as alt text on the image, both for accessibility and for editing the diagram in the future.)

![
https://flowchart.fun/
Start
  Decide
    Continue
      Finish
    Stop
](https://user-images.githubusercontent.com/65359171/137763309-05e4d240-9764-4353-aebf-ae5386c6c60b.jpg)

## Environment Variables

Variable | Purpose
-------- | -------
Variable1 | Variable1 purpose.
Variable2 | Variable2 purpose.
VariableN | VariableN purpose.

## SharePoint Lists // Dataverse Tables

For linking any SP lists you might have, if you're using SharePoint. If your inter-list relationships are complex enough, consider including an entity relationship diagram. Same goes for Dataverse; this section isn't necessary for a simple one or two table solution, but more complex solutions may merit a diagram.

### Development

* [DevelopmentList1](#link)
* [DevelopmentList2](#link)

### Production

* ProductionList1
* ProductionList2

## Automation

See the [Process & Collab Power Platform Actions](https://github.com/niaid/proc-collab-popl-actions) for more information on the actions used by this repository.

### Setup

If you have the [GitHub CLI tool](https://github.com/cli/cli) `gh` installed, it's quite easy to configure environments and secrets from your shell. With the cloned repository as your working directory:

(Note that you may not have access to all of this information; contact [Jack Kinsey](mailto:john.kinsey@nih.gov) as necessary.)

```sh
# Create the necessary environments
gh api -X PUT /repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/environments/development
gh api -X PUT /repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/environments/testing
gh api -X PUT /repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/environments/production

# Add tenant ID for SPN authentication
gh secret set TENANT_ID -b'14b77578-9773-42d5-8507-251ca2dc2b06'

# Add development secrets
gh secret set SOLUTION_NAME --env=development -b'<solution-name>'
gh secret set ENVIRONMENT_URL --env=development -b'https://<dev>.crm9.dynamics.com/'
gh secret set APP_ID --env=development -b'2b888f6b-fb60-4374-8c64-f1cd5bbd500d'
gh secret set CLIENT_SECRET --env=development # Then paste dev client secret on stdin

# Add testing secrets
gh secret set ENVIRONMENT_URL --env=testing -b'https://<test>.crm9.dynamics.com/'
gh secret set APP_ID --env=testing -b'a335e453-a05c-4064-ba33-3edb150c685a'
gh secret set CLIENT_SECRET --env=testing # Then paste test client secret on stdin

# Add production secrets
gh secret set ENVIRONMENT_URL --env=production -b'https://<prod>.crm9.dynamics.com/'
gh secret set APP_ID --env=production -b'b6dff512-16ae-433f-9aa7-bb010cb2f3c1'
gh secret set CLIENT_SECRET --env=production # Then paste prod client secret on stdin

# If you're feeling fancy, you might want to configure Autolinks
# This will cause e.g. "PC-123" in a commit message to render as a link to <https://jira.niaid.nih.gov/browse/PC-123>
gh api -X POST /repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner')/autolinks -f key_prefix='PC-' -f url_template='https://jira.niaid.nih.gov/browse/PC-<num>'

# The repository should be shared at least read-only with the Process & Collaboration team under the NIAID org
gh api -X PUT /orgs/niaid/teams/process-collaboration/repos/$(gh repo view --json nameWithOwner --jq '.nameWithOwner') -f permission='pull'
```

### Deployment Settings

Once you have some environment variables or connection references in your solution--or when you're preparing to deploy to production--you'll need to populate your `testing.deploymentSettings.json` and `production.deploymentSettings.json` files with values.

To get started, make sure you have the Power Apps CLI tool [installed](https://github.com/niaid/proc-collab-hub/wiki/Getting-Started#pac-power-apps-cli). 

Then with the cloned repository as your working directory, run e.g.:

```sh
$ pac solution create-settings -f src -s testing.deploymentSettings.json
$ cp testing.deploymentSettings.json production.deploymentSettings.json 
```

This will generate a deployment settings file with your environment variables and connection references set to blank values. For example:

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "niaid_ENVVAR_PROJ_EmailGroup",
      "Value": ""
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "niaid_CR_PROJ_Outlook",
      "ConnectionId": "",
      "ConnectorId": "/providers/Microsoft.PowerApps/apis/shared_office365"
    }
  ]
}
```

You can then fill in the blank values. Environment variables take text, which is usually self-evident; connection references the connection ID of a relevant connection, which is the unhyphenated GUID found in the URL of the connection (from Power Apps, browse to Data > Connections and choose a connection; the URL will look something like this: `https://make.gov.powerapps.us/environments/[environment-guid]/connections/[connector-id]/[connection-id]/details`).

Filled out, our example might look something like this:

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "niaid_ENVVAR_PROJ_EmailGroup",
      "Value": "testlivelink1@nih.gov"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "niaid_CR_PROJ_Outlook",
      "ConnectionId": "06a88093903d401a82bd65b1ea4b9df5",
      "ConnectorId": "/providers/Microsoft.PowerApps/apis/shared_office365"
    }
  ]
}
```

If you add environment variables or connection references to your solution in the future, be sure to keep your deployment settings up to date; however, note that the `create-settings` command produces a blank template every time, and you'll have to merge the changes into your deployment settings files manually.

### Secrets

Keep the portions of these tables you think are valuable for/specific to your project.

Secret | Value
------ | -----
TENANT_ID | AAD tenant id to authenticate within. Never changes.
APP_ID | AAD app id to authenticate with. We have [one per environment](https://github.com/niaid/proc-collab-hub/wiki/Environments).
CLIENT_SECRET | AAD app client secret to authenticate with. One per environment; contact [Jack Kinsey](mailto:john.kinsey@nih.gov) as necessary.
SOLUTION_NAME | The logical name of the solution to import.
ENVIRONMENT_URL | See Environments. Must be set per environment.

### Environments

Environment | URL
----------- | ---
development | e.g. <https://niaiddev.crm9.dynamics.com/>
testing | e.g. <https://niaidpapatest.crm9.dynamics.com/>
production | e.g. <https://niaid.crm9.dynamics.com/>

### Workflows

* Commit latest solution
  * Secrets: `TENANT_ID`, `APP_ID`, `CLIENT_SECRET`, `SOLUTION_NAME`, `ENVIRONMENT_URL`
  * Environment: `development`
  * Operation: Manual
  * Imports and unpacks the solution, creating a new branch with the contents.

* Check and deploy to testing
  * Secrets: `TENANT_ID`, `APP_ID`, `CLIENT_SECRET`, `ENVIRONMENT_URL`
  * Environment: `testing`
  * Operation: Automated (Runs on push when `src` is changed.)
  * Packs and checks the solution, then deploys to the testing environment as Managed. 

* Release to production
  * Secrets: `TENANT_ID`, `APP_ID`, `CLIENT_SECRET`, `ENVIRONMENT_URL`
  * Environment: `production`
  * Operation: Manual
  * Packs the solution and deploys to the production environment as Managed.
