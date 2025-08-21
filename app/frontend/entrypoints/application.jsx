// import React from 'react'
// import { createRoot } from 'react-dom/client'
// import App from '../components/App'
// import '../index.css'

// // Wait for DOM to be ready
// document.addEventListener('DOMContentLoaded', () => {
//   const container = document.getElementById('root')
//   if (container) {
//     const root = createRoot(container)
//     root.render(<App />)
//   }
// })

import React from 'react'
import ReactDOM from 'react-dom/client'

function App() {
  return <h1>Hello from JSX with Vite!</h1>
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)