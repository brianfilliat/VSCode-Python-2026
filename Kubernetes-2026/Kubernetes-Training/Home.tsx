import { useAuth } from "@/_core/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { useLocation } from "wouter";
import { getLoginUrl } from "@/const";

export default function Home() {
  const { isAuthenticated } = useAuth();
  const navigate = useLocation()[1];

  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <main className="flex-1 flex items-center justify-center px-4 py-12">
        <div className="max-w-2xl w-full text-center">
          <h1 className="text-5xl font-bold mb-4 bg-gradient-to-r from-cyan-400 to-magenta-500 bg-clip-text text-transparent">
            Kubernetes Training
          </h1>
          <p className="text-xl text-slate-300 mb-8">
            Complete reference guide for Kubernetes concepts, architecture, and best practices
          </p>

          {isAuthenticated ? (
            <Button
              onClick={() => navigate("/training")}
              size="lg"
              className="bg-gradient-to-r from-cyan-500 to-cyan-600 hover:from-cyan-600 hover:to-cyan-700 text-white font-semibold px-8 py-3 rounded-lg transition-all duration-200 transform hover:scale-105"
            >
              Access Training Materials
            </Button>
          ) : (
            <Button
              onClick={() => (window.location.href = getLoginUrl())}
              size="lg"
              className="bg-gradient-to-r from-cyan-500 to-cyan-600 hover:from-cyan-600 hover:to-cyan-700 text-white font-semibold px-8 py-3 rounded-lg transition-all duration-200 transform hover:scale-105"
            >
              Sign In to Access Training
            </Button>
          )}
        </div>
      </main>
    </div>
  );
}
