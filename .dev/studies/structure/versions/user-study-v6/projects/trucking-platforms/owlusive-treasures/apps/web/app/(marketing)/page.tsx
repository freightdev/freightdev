'use client'

export default function LoginPage() {
  return (
    <main className="flex items-center justify-center min-h-screen px-4 bg-gray-100">
      <div className="w-full max-w-md p-8 space-y-6 bg-white shadow-xl rounded-xl">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900">Sign In</h1>
          <p className="mt-1 text-sm text-gray-500">Access your account</p>
        </div>

        <form className="space-y-5">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              type="email"
              id="email"
              className="w-full px-4 py-2 mt-1 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
              placeholder="you@example.com"
              required
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              type="password"
              id="password"
              className="w-full px-4 py-2 mt-1 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            className="w-full px-4 py-2 font-medium text-white transition bg-blue-600 rounded-md hover:bg-blue-700"
          >
            Sign In
          </button>
        </form>

        <p className="text-sm text-center text-gray-500">
          Don’t have an account?{' '}
          <a href="/register" className="text-blue-600 hover:underline">
            Sign up
          </a>
        </p>
      </div>
    </main>
  )
}
