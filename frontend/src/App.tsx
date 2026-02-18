import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Layout } from './components/layout/Layout';
import { SubmitProgram } from './pages/SubmitProgram';
import { SubmitConfirmation } from './pages/SubmitConfirmation';
import { SearchPrograms } from './pages/SearchPrograms';

/**
 * Root application component.
 *
 * Sets up react-router with Ontario Design System layout wrapper
 * and defines routes for the citizen portal pages.
 */
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<SubmitProgram />} />
          <Route path="/confirmation" element={<SubmitConfirmation />} />
          <Route path="/search" element={<SearchPrograms />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
