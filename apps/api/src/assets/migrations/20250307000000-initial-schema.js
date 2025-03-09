const fs = require('fs');
const path = require('path');

module.exports = {
  async up(queryInterface, Sequelize) {
    // Read the SQL file content
    const sqlPath = path.join(__dirname, 'initial.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Split the SQL file into individual statements
    const statements = sql.split(';').filter(statement => statement.trim());
    
    // Execute each SQL statement
    const transaction = await queryInterface.sequelize.transaction();
    try {
      for (const statement of statements) {
        if (statement.trim()) {
          await queryInterface.sequelize.query(`${statement};`, { transaction });
        }
      }
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    // Drop all tables in reverse order to handle foreign key constraints
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS documents;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS case_events;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS team_members;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS teams;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS cases;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS enrollments;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS courses;', { transaction });
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS users;', { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
};