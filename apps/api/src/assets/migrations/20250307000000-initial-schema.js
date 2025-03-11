// eslint-disable-next-line @typescript-eslint/no-require-imports
const fs = require('fs');
// eslint-disable-next-line @typescript-eslint/no-require-imports
const path = require('path');

module.exports = {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async up(queryInterface, Sequelize) {
    // First check if users table already exists to make the migration idempotent
    const tableExists = await queryInterface.sequelize
      .query(
        `SELECT EXISTS (
          SELECT FROM information_schema.tables
          WHERE table_schema = 'public'
          AND table_name = 'users'
        );`,
        { type: queryInterface.sequelize.QueryTypes.SELECT }
      )
      .then(result => result[0].exists);

    // If tables already exist, skip this migration
    if (tableExists) {
      console.log('Tables already exist, skipping initial schema creation');
      return;
    }

    // Continue with original migration code
    const sqlPath = path.join(__dirname, 'initial.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Split the SQL file into individual statements
    const statements = sql.split(';').filter(statement => statement.trim());

    // Execute each SQL statement
    const transaction = await queryInterface.sequelize.transaction();
    try {
      for (const statement of statements) {
        if (statement.trim()) {
          await queryInterface.sequelize.query(`${statement};`, {
            transaction,
          });
        }
      }
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async down(queryInterface, Sequelize) {
    // Drop all tables in reverse order to handle foreign key constraints
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS documents;', {
        transaction,
      });
      await queryInterface.sequelize.query(
        'DROP TABLE IF EXISTS case_events;',
        { transaction },
      );
      await queryInterface.sequelize.query(
        'DROP TABLE IF EXISTS team_members;',
        { transaction },
      );
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS teams;', {
        transaction,
      });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS cases;', {
        transaction,
      });
      await queryInterface.sequelize.query(
        'DROP TABLE IF EXISTS enrollments;',
        { transaction },
      );
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS courses;', {
        transaction,
      });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS users;', {
        transaction,
      });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
