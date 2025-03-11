'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    try {
      // Check if the column already exists
      const columnExists = await queryInterface.sequelize
        .query(
          `SELECT EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_name = 'users'
            AND column_name = 'profile_image'
          );`,
          { type: queryInterface.sequelize.QueryTypes.SELECT }
        )
        .then(result => result[0].exists);

      if (!columnExists) {
        console.log('Adding profile_image column to users table');
        await queryInterface.addColumn('users', 'profile_image', {
          type: Sequelize.STRING,
          allowNull: true,
        });
        console.log('Successfully added profile_image column');
      } else {
        console.log('profile_image column already exists, skipping');
      }
    } catch (error) {
      console.error('Error adding profile_image column:', error.message);
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    try {
      // Check if the column exists before trying to remove it
      const columnExists = await queryInterface.sequelize
        .query(
          `SELECT EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_name = 'users'
            AND column_name = 'profile_image'
          );`,
          { type: queryInterface.sequelize.QueryTypes.SELECT }
        )
        .then(result => result[0].exists);

      if (columnExists) {
        console.log('Removing profile_image column from users table');
        await queryInterface.removeColumn('users', 'profile_image');
        console.log('Successfully removed profile_image column');
      } else {
        console.log('profile_image column does not exist, skipping');
      }
    } catch (error) {
      console.error('Error removing profile_image column:', error.message);
      throw error;
    }
  }
};
