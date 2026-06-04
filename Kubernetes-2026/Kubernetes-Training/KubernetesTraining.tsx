import { useState, useMemo } from "react";
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Spinner } from "@/components/ui/spinner";
import { Search, Download, RotateCcw, AlertCircle } from "lucide-react";
import { useAuth } from "@/_core/hooks/useAuth";
import { toast } from "sonner";
import EditableSection from "@/components/EditableSection";
import EditableTable from "@/components/EditableTable";
import "./KubernetesTraining.css";

export default function KubernetesTraining() {
  const { user } = useAuth();
  const [selectedTopic, setSelectedTopic] = useState<string>("kubernetes-architecture");
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState("overview");

  // Fetch all topics
  const { data: topics, isLoading: topicsLoading } = trpc.training.getTopics.useQuery();

  // Fetch selected topic with all sections
  const { data: topicData, isLoading: topicLoading } = trpc.training.getTopicBySlug.useQuery(
    { slug: selectedTopic },
    { enabled: !!selectedTopic }
  );

  // Filter sections based on search query
  const filteredSections = useMemo(() => {
    if (!topicData?.sections) return [];
    if (!searchQuery) return topicData.sections;

    return topicData.sections.filter((section) =>
      section.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      section.content?.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [topicData?.sections, searchQuery]);

  // Export mutations
  const exportJSONMutation = trpc.training.exportJSON.useQuery(undefined, { enabled: false });
  const exportHTMLMutation = trpc.training.exportHTML.useQuery(undefined, { enabled: false });
  const resetMutation = trpc.training.resetToOriginal.useMutation({
    onSuccess: () => {
      toast.success("Content reset to original");
      // Refetch topics
      trpc.useUtils().training.getTopics.invalidate();
      trpc.useUtils().training.getTopicBySlug.invalidate();
    },
    onError: (error) => {
      toast.error(error.message || "Failed to reset content");
    },
  });

  const handleExportJSON = async () => {
    try {
      const data = await exportJSONMutation.refetch();
      if (data.data) {
        const blob = new Blob([JSON.stringify(data.data, null, 2)], { type: "application/json" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `kubernetes-training-${new Date().toISOString().split("T")[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        toast.success("Exported as JSON");
      }
    } catch (error) {
      toast.error("Failed to export JSON");
    }
  };

  const handleExportHTML = async () => {
    try {
      const data = await exportHTMLMutation.refetch();
      if (data.data) {
        const blob = new Blob([data.data], { type: "text/html" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `kubernetes-training-${new Date().toISOString().split("T")[0]}.html`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        toast.success("Exported as HTML");
      }
    } catch (error) {
      toast.error("Failed to export HTML");
    }
  };

  const handleReset = () => {
    if (!confirm("Are you sure you want to reset all content to the original? This cannot be undone.")) {
      return;
    }
    resetMutation.mutate();
  };

  if (topicsLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Spinner />
      </div>
    );
  }

  return (
    <div className="kubernetes-training-container">
      {/* Header */}
      <div className="training-header">
        <div className="header-content">
          <h1 className="header-title">Kubernetes Training Reference</h1>
          <p className="header-subtitle">
            Complete guide to Kubernetes concepts, architecture, and best practices
          </p>
        </div>

        {/* Action Buttons */}
        <div className="header-actions">
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportJSON}
            className="action-button"
          >
            <Download className="w-4 h-4 mr-2" />
            JSON
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportHTML}
            className="action-button"
          >
            <Download className="w-4 h-4 mr-2" />
            HTML
          </Button>
          {user?.role === "admin" && (
            <Button
              variant="outline"
              size="sm"
              onClick={handleReset}
              disabled={resetMutation.isPending}
              className="action-button admin-button"
            >
              <RotateCcw className="w-4 h-4 mr-2" />
              Reset
            </Button>
          )}
        </div>
      </div>

      <div className="training-content">
        {/* Sidebar - Topics Navigation */}
        <aside className="topics-sidebar">
          <div className="sidebar-header">
            <h2 className="sidebar-title">Topics</h2>
          </div>

          <div className="topics-list">
            {topics?.map((topic) => (
              <button
                key={topic.id}
                onClick={() => {
                  setSelectedTopic(topic.slug);
                  setSearchQuery("");
                }}
                className={`topic-button ${selectedTopic === topic.slug ? "active" : ""}`}
              >
                <span className="topic-icon">{topic.icon || "📚"}</span>
                <span className="topic-name">{topic.title}</span>
              </button>
            ))}
          </div>
        </aside>

        {/* Main Content Area */}
        <main className="training-main">
          {/* Search Bar */}
          <div className="search-container">
            <Search className="search-icon" />
            <Input
              placeholder="Search topics, sections, and content..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
          </div>

          {/* Tabs for Organization */}
          <Tabs value={activeTab} onValueChange={setActiveTab} className="content-tabs">
            <TabsList className="tabs-list">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="sections">Sections</TabsTrigger>
              <TabsTrigger value="tables">Tables</TabsTrigger>
              <TabsTrigger value="notes">Notes</TabsTrigger>
            </TabsList>

            {/* Overview Tab */}
            <TabsContent value="overview" className="tab-content">
              {topicData && (
                <Card className="overview-card">
                  <CardHeader>
                    <CardTitle>{topicData.title}</CardTitle>
                    <CardDescription>{topicData.description}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="overview-metadata">
                      <Badge variant="secondary">
                        {topicData.sections?.length || 0} Sections
                      </Badge>
                      <Badge variant="secondary">
                        {topicData.sections?.reduce(
                          (acc, s) => acc + (s.tables?.length || 0),
                          0
                        ) || 0} Tables
                      </Badge>
                      <Badge variant="secondary">
                        {topicData.sections?.reduce(
                          (acc, s) => acc + (s.notes?.length || 0),
                          0
                        ) || 0} Notes
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              )}
            </TabsContent>

            {/* Sections Tab */}
            <TabsContent value="sections" className="tab-content">
              {topicLoading ? (
                <div className="flex justify-center py-8">
                  <Spinner />
                </div>
              ) : filteredSections.length > 0 ? (
                <div className="sections-container">
                  {filteredSections.map((section) => (
                    <EditableSection
                      key={section.id}
                      section={section}
                      isEditable={!!user}
                    />
                  ))}
                </div>
              ) : (
                <div className="empty-state">
                  <p>No sections found matching your search.</p>
                </div>
              )}
            </TabsContent>

            {/* Tables Tab */}
            <TabsContent value="tables" className="tab-content">
              <div className="tables-container">
                {topicData?.sections?.map((section) =>
                  section.tables?.map((table) => (
                    <EditableTable
                      key={table.id}
                      table={table}
                      sectionTitle={section.title}
                      isEditable={!!user}
                    />
                  ))
                )}
              </div>
            </TabsContent>

            {/* Notes Tab */}
            <TabsContent value="notes" className="tab-content">
              <div className="notes-container">
                {topicData?.sections?.map((section) =>
                  section.notes?.map((note) => (
                    <Card key={note.id} className="note-card">
                      <CardHeader>
                        <div className="note-header">
                          <Badge variant="outline">{note.noteType}</Badge>
                          {note.title && <CardTitle className="note-title">{note.title}</CardTitle>}
                        </div>
                      </CardHeader>
                      <CardContent>
                        <p className="note-content">{note.content}</p>
                      </CardContent>
                    </Card>
                  ))
                )}
              </div>
            </TabsContent>
          </Tabs>
        </main>
      </div>
    </div>
  );
}
