export default {
  '*.rb': ['bin/rubocop --autocorrect'],
  '*.{js,mjs}': ['prettier --write'],
  '*.{yml,yaml}': (files) => {
    // Skip erb template files like cucumber.yml
    const yamlFiles = files.filter(file => !file.includes('cucumber.yml'));
    return yamlFiles.length > 0 ? [`yamllint ${yamlFiles.join(' ')}`] : [];
  },
};
