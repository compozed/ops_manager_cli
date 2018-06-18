# Change Log

## [v0.7.6](https://github.com/compozed/ops_manager_cli/tree/v0.7.6) (2018-06-18)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.7.5...v0.7.6)

**Closed issues:**

- Upgrading Product Issue - The enabled\_errands parameter is no longer supported [\#35](https://github.com/compozed/ops_manager_cli/issues/35)
- Ops Manager cannot deploy appliance when there is no Ops Manager appliance deployed [\#31](https://github.com/compozed/ops_manager_cli/issues/31)
- OpsMAnagerCli should check if there are pending changes in the current installation before performing an opsman upgrade [\#30](https://github.com/compozed/ops_manager_cli/issues/30)
- director generator does not remove fixed stemcell versions [\#18](https://github.com/compozed/ops_manager_cli/issues/18)
- Remove ovftools dependency and use rbvmomi instead to deploy appliance [\#14](https://github.com/compozed/ops_manager_cli/issues/14)

**Merged pull requests:**

- Make it work with ruby other than 2.4 [\#38](https://github.com/compozed/ops_manager_cli/pull/38) ([teancom](https://github.com/teancom))
- Remove pem values from product templates [\#37](https://github.com/compozed/ops_manager_cli/pull/37) ([suppalapati13](https://github.com/suppalapati13))

## [v0.7.5](https://github.com/compozed/ops_manager_cli/tree/v0.7.5) (2018-01-18)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.7.4...v0.7.5)

## [v0.7.4](https://github.com/compozed/ops_manager_cli/tree/v0.7.4) (2017-11-22)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.7.2...v0.7.4)

## [v0.7.2](https://github.com/compozed/ops_manager_cli/tree/v0.7.2) (2017-11-03)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.7.1...v0.7.2)

## [v0.7.1](https://github.com/compozed/ops_manager_cli/tree/v0.7.1) (2017-10-25)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.7.0...v0.7.1)

## [v0.7.0](https://github.com/compozed/ops_manager_cli/tree/v0.7.0) (2017-10-20)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.5.4...v0.7.0)

**Closed issues:**

- OpsMAnagerCli should support new errands endpoint in versions \>= 1.10 [\#32](https://github.com/compozed/ops_manager_cli/issues/32)

**Merged pull requests:**

- Added support for ops\_manager\_cli to deploy via AWS [\#34](https://github.com/compozed/ops_manager_cli/pull/34) ([geofffranks](https://github.com/geofffranks))
- Add pending-changes CLI command [\#26](https://github.com/compozed/ops_manager_cli/pull/26) ([RMeharg](https://github.com/RMeharg))

## [v0.5.4](https://github.com/compozed/ops_manager_cli/tree/v0.5.4) (2017-06-27)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.5.3...v0.5.4)

## [v0.5.3](https://github.com/compozed/ops_manager_cli/tree/v0.5.3) (2017-06-27)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.5.2...v0.5.3)

## [v0.5.2](https://github.com/compozed/ops_manager_cli/tree/v0.5.2) (2017-06-27)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.5.1...v0.5.2)

**Closed issues:**

- CLI should check that UAA is available after Ops Manager upgrades [\#29](https://github.com/compozed/ops_manager_cli/issues/29)
- When upgrading opsman the token does not reset [\#27](https://github.com/compozed/ops_manager_cli/issues/27)
- Support refresh tokens for re-authentication with UAA [\#24](https://github.com/compozed/ops_manager_cli/issues/24)
- Allow toggling ops\_manager.log [\#21](https://github.com/compozed/ops_manager_cli/issues/21)

## [v0.5.1](https://github.com/compozed/ops_manager_cli/tree/v0.5.1) (2017-01-25)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.5.0...v0.5.1)

**Closed issues:**

- Upgrading product does not work with opsman\_cli 0.5.0 on opsman 1.9 [\#23](https://github.com/compozed/ops_manager_cli/issues/23)

## [v0.5.0](https://github.com/compozed/ops_manager_cli/tree/v0.5.0) (2017-01-24)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.4.1...v0.5.0)

**Implemented enhancements:**

- Support DELETE on curl [\#19](https://github.com/compozed/ops_manager_cli/pull/19) ([glyn](https://github.com/glyn))

**Closed issues:**

- Upgrade does not merge product installation settings [\#22](https://github.com/compozed/ops_manager_cli/issues/22)
- ops\_manager curl -x PUT not working [\#17](https://github.com/compozed/ops_manager_cli/issues/17)
- When uploading stemcell it does not show the correct output [\#15](https://github.com/compozed/ops_manager_cli/issues/15)

## [v0.4.1](https://github.com/compozed/ops_manager_cli/tree/v0.4.1) (2016-10-21)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.4.0...v0.4.1)

**Fixed bugs:**

- Director template generator does not delete UAA sensitive data [\#13](https://github.com/compozed/ops_manager_cli/issues/13)
- Product template generator does not delete stemcell metadata properties [\#12](https://github.com/compozed/ops_manager_cli/issues/12)

## [v0.4.0](https://github.com/compozed/ops_manager_cli/tree/v0.4.0) (2016-10-20)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.3.0...v0.4.0)

**Implemented enhancements:**

- Improve output for appliance deploy/upgrade [\#11](https://github.com/compozed/ops_manager_cli/issues/11)
- Improve output for product deploy/upgrade [\#10](https://github.com/compozed/ops_manager_cli/issues/10)
- Run errands when applying changes [\#9](https://github.com/compozed/ops_manager_cli/issues/9)
- 1.8 support [\#5](https://github.com/compozed/ops_manager_cli/pull/5) ([bonzofenix](https://github.com/bonzofenix))

**Fixed bugs:**

- delete-unused-products command not working [\#8](https://github.com/compozed/ops_manager_cli/issues/8)
- Hardcoded user name admin when logging agains ops\_manager [\#2](https://github.com/compozed/ops_manager_cli/issues/2)

**Closed issues:**

- Link to CLA is broken [\#4](https://github.com/compozed/ops_manager_cli/issues/4)

**Merged pull requests:**

- Ensures special shell characters are escaped in ovftool command [\#7](https://github.com/compozed/ops_manager_cli/pull/7) ([kpschuck](https://github.com/kpschuck))
- Fix issue when collecting errands for applying changes [\#6](https://github.com/compozed/ops_manager_cli/pull/6) ([kpschuck](https://github.com/kpschuck))
- Replaces hardcoded 'admin' username with user from login command [\#3](https://github.com/compozed/ops_manager_cli/pull/3) ([kpschuck](https://github.com/kpschuck))

## [v0.3.0](https://github.com/compozed/ops_manager_cli/tree/v0.3.0) (2016-09-03)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.2.8...v0.3.0)

## [v0.2.8](https://github.com/compozed/ops_manager_cli/tree/v0.2.8) (2016-08-09)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.2.7...v0.2.8)

## [v0.2.7](https://github.com/compozed/ops_manager_cli/tree/v0.2.7) (2016-07-28)
[Full Changelog](https://github.com/compozed/ops_manager_cli/compare/v0.1.1...v0.2.7)

## [v0.1.1](https://github.com/compozed/ops_manager_cli/tree/v0.1.1) (2016-05-06)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*