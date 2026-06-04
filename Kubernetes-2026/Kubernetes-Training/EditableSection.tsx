import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Edit2, Save, X } from "lucide-react";
import { trpc } from "@/lib/trpc";
import { toast } from "sonner";

interface EditableSectionProps {
  section: {
    id: number;
    title: string;
    content?: string | null;
    tables?: any[];
    notes?: any[];
  };
  isEditable: boolean;
}

export default function EditableSection({ section, isEditable }: EditableSectionProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [content, setContent] = useState(section.content || "");
  const utils = trpc.useUtils();

  const updateMutation = trpc.training.updateSectionContent.useMutation({
    onSuccess: () => {
      toast.success("Section updated successfully");
      setIsEditing(false);
      utils.training.getTopicBySlug.invalidate();
    },
    onError: () => {
      toast.error("Failed to update section");
    },
  });

  const handleSave = async () => {
    if (content === section.content) {
      setIsEditing(false);
      return;
    }
    await updateMutation.mutateAsync({
      sectionId: section.id,
      content,
    });
  };

  const handleCancel = () => {
    setContent(section.content || "");
    setIsEditing(false);
  };

  return (
    <Card className="editable-section-card">
      <CardHeader className="section-header">
        <div className="section-header-content">
          <CardTitle className="section-title">{section.title}</CardTitle>
          {isEditable && !isEditing && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsEditing(true)}
              className="edit-button"
            >
              <Edit2 className="w-4 h-4" />
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="section-content">
        {isEditing ? (
          <div className="edit-mode">
            <Textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="section-textarea"
              rows={6}
            />
            <div className="edit-actions">
              <Button
                size="sm"
                onClick={handleSave}
                disabled={updateMutation.isPending}
                className="save-button"
              >
                <Save className="w-4 h-4 mr-2" />
                Save
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={handleCancel}
                disabled={updateMutation.isPending}
              >
                <X className="w-4 h-4 mr-2" />
                Cancel
              </Button>
            </div>
          </div>
        ) : (
          <div className="view-mode">
            <p className="section-text">{content || "No content yet"}</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
