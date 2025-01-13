<h1 align="center">
  <img src="https://zap-notes.com/logo.jpeg" alt="Logo" width="128" style="border-radius: 50%;">
  <br />
  Zap Notes App
</h1>

<p align="center">
  <a href="https://zap-notes.com">Website</a>
  ·
  <a href="https://github.com/ZapNotesApp/ZapNotesApp/releases">Releases</a>
  <br />
  <br />
  AI-powered note-taking application for recording and analyzing thoughts, ideas, and tasks.
</p>

<div align="center">
  <a href="https://github.com/ZapNotesApp/ZapNotesApp/network/members">
    <img src="https://img.shields.io/github/forks/ZapNotesApp/ZapNotesApp" alt="Forks">
  </a>
  <a href="https://github.com/ZapNotesApp/ZapNotesApp/stargazers">
    <img src="https://img.shields.io/github/stars/ZapNotesApp/ZapNotesApp" alt="Stars">
  </a>
  <a href="https://github.com/ZapNotesApp/ZapNotesApp/issues">
    <img src="https://img.shields.io/github/issues/ZapNotesApp/ZapNotesApp" alt="Issues">
  </a>
  <a href="https://github.com/ZapNotesApp/ZapNotesApp/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-GPLv3-blue" alt="License">
  </a>
  <a href="https://github.com/ZapNotesApp/ZapNotesApp">
    <img src="https://img.shields.io/github/repo-size/ZapNotesApp/ZapNotesApp" alt="Repo Size">
  </a>
  <a href="https://github.com/ZapNotesApp/ZapNotesApp-backend">
    <img src="https://img.shields.io/badge/Backend-Code-green" alt="Backend Code">
  </a>
</div>

## Try Zap Notes App

<a href="https://apps.apple.com/us/app/zap-notes/id6740298881">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" style="width:150px;">
</a>

## Demo

<table>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/252a1cc0-d6e0-4299-ac2f-a67e7a6db4ea" alt="Ultramarine iPhone 16 Mockup" width="300"/>
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/e3150e63-25ed-439a-9679-c41243d289a6" alt="iPhone 15 Pro Hand Mockup" width="300"/>
    </td>
  </tr>
</table>

https://github.com/user-attachments/assets/2e255ff0-29e8-4d3b-8e83-38bc0f9988f3

## Features

- ✨ Multi-modal input: Text, voice, and photo capture
- 🤖 AI-powered note summarization
- 🌆 Image analysis and description
- 🎤 Smart audio transcription
- 📋 Note management (add, edit, delete, mark as complete)
- 🎨 Customizable appearance settings

## Planned Features

- 🏷 Enhanced AI-powered categorization and tagging
- 🔁 Cross-platform synchronization
- ✅ Multi-platform support

## Project Structure

The project is organized into several key components:

- `ContentView.swift`: The main entry point of the app
- `HomeView.swift`: The primary view for displaying and managing notes
- `NoteRowView.swift`: Individual note display component
- `AudioNoteView.swift`: Audio recording and transcription functionality
- `ImagePicker.swift`: Photo and video capture functionality
- `FullScreenMediaView.swift`: Full-screen media viewing
- `AppearanceSettingsView.swift`: Customizable appearance settings
- `AIManager.swift`: Handles AI-related operations (summarization, image analysis, transcription)
- Backend code: [GitHub Repo](https://github.com/ZapNotesApp/ZapNotesApp-backend)

## For AI or Contributors

This project has recently integrated AI capabilities. The main focus areas for future development include:

1. Enhancing AI-powered categorization and tagging of notes
2. Developing cross-platform synchronization capabilities
3. Expanding to support multiple platforms (iOS, macOS, web)
4. Improving AI model accuracy and performance

When contributing to this project, please follow the commit message guidelines provided below to maintain a clean and organized project history.

## Commit Message Guidelines

To maintain a clean and organized project history, please follow these commit message guidelines:

### Format:
```
type: subject
```

### General Rules:
- Separate different types of changes into different commits.
- Keep the subject concise, no more than 50 characters.
- Use English consistently.
- For detailed explanations, add a blank line after the subject.

### Commit Types:
- `feat`:  New feature
- `fix`:  Bug fix
- `refactor`:  Code refactoring
- `docs`:  Documentation changes
- `style`:  Code style changes (not CSS)
- `test`:  Test case modifications
- `chore`:  Other changes (e.g., build process, dependencies)

### Examples:
```
feat: add user login functionality
fix: resolve slow loading issue on homepage
docs: update project description in README.md
style: standardize code indentation
refactor: restructure data processing module
test: add unit tests for user registration
chore: update dependency versions in package.json
```

### Detailed Example:
```
feat: add user login functionality

- Implement JWT authentication
- Create login form component
- Add login state management

Related issue: #123
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contact

Contact Zigao Wang at a@zigao.wang, or open an issue: https://github.com/ZapNotesApp/ZapNotesApp/issues
