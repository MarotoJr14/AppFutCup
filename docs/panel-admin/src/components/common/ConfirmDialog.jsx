export default function ConfirmDialog({ message, onConfirm, onCancel }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="bg-surface border border-error rounded-xl w-full max-w-sm p-6">
        <h3 className="text-lg font-bold text-error mb-2">Confirmar eliminación</h3>
        <p className="text-white mb-6">{message}</p>
        <div className="flex gap-3 justify-end">
          <button onClick={onCancel} className="btn-secondary">Cancelar</button>
          <button onClick={onConfirm} className="btn-danger">Eliminar</button>
        </div>
      </div>
    </div>
  )
}
