const { query } = require('./src/config/postgres');

async function checkSchema() {
  try {
    const res = await query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'polling_checklists'
    `);
    console.log('Columns in polling_checklists:', JSON.stringify(res, null, 2));
    
    const res2 = await query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'carpools'
    `);
    console.log('Columns in carpools:', JSON.stringify(res2, null, 2));

    const res3 = await query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'i_voted_records'
    `);
    console.log('Columns in i_voted_records:', JSON.stringify(res3, null, 2));

  } catch (err) {
    console.error('Error checking schema:', err);
  } finally {
    process.exit();
  }
}

checkSchema();
