import CreateStudentClient from './CreateStudentClient';

import { Suspense } from 'react';

export default function CreateStudentPage() {
  return (
    <Suspense fallback={<div>Cargando módulo de estudiante...</div>}>
      <CreateStudentClient />
    </Suspense>
  );
}
