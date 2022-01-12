import { task } from 'hardhat/config';
import { printContracts,setDRE } from '../../helpers/misc-utils';

task('print-contracts', 'Inits the DRE, to have access to all the plugins').setAction(
  async ({}, localBRE) => {
    setDRE(localBRE);
    // await localBRE.run('set-DRE');
    printContracts();
  }
);
