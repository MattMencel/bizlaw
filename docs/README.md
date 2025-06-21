# Legal Simulation Platform Documentation

This directory contains the user documentation website for the Legal Simulation Platform, built with [Docusaurus](https://docusaurus.io/).

## 🌐 Live Documentation

The documentation is automatically deployed to GitHub Pages at:
**https://matt.mencel.github.io/bizlaw/**

## 🚀 Local Development

### Prerequisites
- Node.js 18+
- npm

### Setup and Run
```bash
cd docs
npm install
npm start
```

This starts a local development server at `http://localhost:3000`. Most changes are reflected live without needing to restart the server.

### Build for Production
```bash
npm run build
```

This generates static content into the `build` directory for deployment.

## 📁 Documentation Structure

```
docs/
├── docs/                    # Documentation content
│   ├── getting-started/     # Platform overview and setup
│   ├── students/           # Student user guides
│   ├── instructors/        # Instructor documentation
│   ├── admins/             # Administrator guides
│   └── api/                # API reference
├── src/                    # Custom pages and components
├── static/                 # Static assets (images, files)
├── docusaurus.config.ts    # Site configuration
└── sidebars.ts             # Navigation structure
```

## 📝 Content Guidelines

### Writing Style
- **Clear and concise**: Use simple language suitable for educational users
- **Step-by-step instructions**: Break complex processes into numbered steps
- **Visual aids**: Include screenshots and diagrams where helpful
- **Consistent formatting**: Follow established patterns for headings, lists, and code blocks

### Markdown Features
- Use standard Markdown with Docusaurus enhancements
- Add admonitions (:::tip, :::warning, :::info) for important information
- Include code blocks with syntax highlighting
- Link between documentation pages using relative paths

### Content Organization
- **Getting Started**: Basic platform concepts and initial setup
- **Students**: Task-oriented guides for student users
- **Instructors**: Course management and administration
- **Admins**: System configuration and management
- **API**: Technical integration documentation

## 🔄 Deployment

Documentation is automatically deployed via GitHub Actions when changes are pushed to the `main` branch in the `/docs` directory.

### Manual Deployment
```bash
npm run build
npm run serve  # Test locally
# Deployment happens automatically via GitHub Actions
```

## 🛠️ Customization

### Site Configuration
Edit `docusaurus.config.ts` to modify:
- Site metadata (title, tagline, URL)
- Navigation bar and footer
- Plugin configurations
- Theme settings

### Sidebar Navigation
Edit `sidebars.ts` to modify the documentation structure and navigation menu.

### Styling
- Custom CSS: `src/css/custom.css`
- React components: `src/components/`
- Page layouts: `src/pages/`

## 📊 Features

### Built-in Features
- **Full-text search**: Automatically indexes all content
- **Mobile responsive**: Optimized for all device sizes
- **Dark mode**: Automatic theme switching
- **Versioning**: Support for multiple documentation versions (if needed)
- **Internationalization**: Multi-language support (if needed)

### Analytics and Monitoring
- GitHub Pages provides basic analytics
- Can be extended with Google Analytics if needed

## 🤝 Contributing

### Adding New Documentation
1. Create new `.md` files in the appropriate directory
2. Update `sidebars.ts` to include new pages in navigation
3. Follow existing content patterns and style guidelines
4. Test locally before committing

### Updating Existing Content
1. Edit the relevant `.md` files
2. Use relative links for internal documentation references
3. Maintain consistency with existing formatting
4. Preview changes locally

### Screenshots and Media
- Add images to `static/img/` directory
- Reference images using `/img/filename.png` in markdown
- Optimize images for web (recommended: PNG/JPG, <500KB)
- Include alt text for accessibility

## 🐛 Troubleshooting

### Common Issues
- **Build errors**: Check that all sidebar references point to existing files
- **Broken links**: Use relative paths and verify file locations
- **Styling issues**: Clear browser cache and check custom CSS

### Local Development
- Clear npm cache: `npm start -- --clear`
- Reset and reinstall: `rm -rf node_modules && npm install`
- Check Node.js version compatibility

## 📋 TODO

High priority documentation pages to complete:

### Students (High Priority)
- [ ] Evidence Vault detailed guide
- [ ] Negotiation process and strategy
- [ ] Team collaboration tools

### Instructors (High Priority)
- [ ] Course creation step-by-step
- [ ] Student monitoring dashboard
- [ ] Grading and assessment tools

### API Documentation (Medium Priority)
- [ ] Authentication and API keys
- [ ] REST endpoint reference
- [ ] Integration examples

---

**For questions or technical issues with the documentation site, please create an issue in the main repository.**
