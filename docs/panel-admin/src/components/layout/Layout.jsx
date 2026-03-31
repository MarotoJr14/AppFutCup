import Header from './Header'

export default function Layout({ title, children }) {
  return (
    <div className="min-h-screen bg-bg">
      <Header title={title} />
      <main className="max-w-7xl mx-auto px-4 py-6">{children}</main>
    </div>
  )
}
